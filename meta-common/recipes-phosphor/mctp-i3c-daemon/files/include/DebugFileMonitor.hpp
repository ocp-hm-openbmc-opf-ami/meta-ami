#pragma once

#include "mctp-app-log.hpp"
#include "utils.hpp"

#include <sys/inotify.h>
#include <unistd.h>

#include <boost/asio.hpp>
#include <boost/asio/posix/stream_descriptor.hpp>

#include <algorithm>
#include <fstream>
#include <sstream>
#include <string>
#include <vector>

using boost::asio::posix::stream_descriptor;

class DebugFileMonitor
{
  public:
    DebugFileMonitor(boost::asio::io_context& io_context,
                     const std::string& directory, const std::string& file) :
        io(io_context), directoryPath(directory), fileName(file), inotifyFd(-1),
        watchDescriptor(-1), descriptor(nullptr)
    {}

    ~DebugFileMonitor()
    {
        stop();
    }

    int start()
    {
        // Initialize inotify
        inotifyFd = inotify_init1(IN_NONBLOCK | IN_CLOEXEC);
        if (inotifyFd < 0)
        {
            mctpPrErr("inotify_init1 failed");
            return -1;
        }

        // Add watch on directory
        watchDescriptor = inotify_add_watch(
            inotifyFd, directoryPath.c_str(),
            IN_CREATE | IN_MODIFY | IN_DELETE | IN_MOVED_TO | IN_MOVED_FROM);

        if (watchDescriptor < 0)
        {
            mctpPrErr("inotify_add_watch failed");
            close(inotifyFd);
            inotifyFd = -1;
            return -1;
        }

        // Create stream descriptor for async operations
        descriptor = std::make_unique<stream_descriptor>(io, inotifyFd);

        // Start async read
        asyncWaitForEvents();

        mctpPrInfo("Debug file monitor started for: %s", directoryPath.c_str());
        return 0;
    }

    void stop()
    {
        if (watchDescriptor >= 0)
        {
            inotify_rm_watch(inotifyFd, watchDescriptor);
            watchDescriptor = -1;
        }

        if (descriptor)
        {
            boost::system::error_code ec;
            descriptor->close(ec);
            descriptor = nullptr;
        }

        if (inotifyFd >= 0)
        {
            close(inotifyFd);
            inotifyFd = -1;
        }

        mctpPrInfo("Debug file monitor stopped");
    }

    void readDebugFile(const std::string& filePath)
    {
        int debugLevel = -1;
        bool foundI3C = false;
        std::ifstream file(filePath);
        if (!file)
        {
            mctpPrErr("Debug file not found: %s", filePath.c_str());
            return;
        }

        std::string line;
        if (!std::getline(file, line))
        {
            mctpPrErr("Empty debug file");
            return;
        }

        // Remove all double quotes
        line.erase(std::remove(line.begin(), line.end(), '\"'), line.end());

        std::stringstream ss(line);
        std::vector<std::string> tokens;
        std::string token;

        while (std::getline(ss, token, ','))
        {
            // trim spaces
            token.erase(0, token.find_first_not_of(" \t"));
            token.erase(token.find_last_not_of(" \t") + 1);
            tokens.push_back(token);
        }

        if (tokens.empty())
        {
            mctpPrErr("No tokens found in debug file");
            return;
        }

        for (const auto& t : tokens)
        {
            std::string token = t;
            std::transform(token.begin(), token.end(), token.begin(),
                           ::tolower);

            size_t colonPos = token.find(':');
            if (colonPos != std::string::npos)
            {
                // Split by ':' into parts
                std::vector<std::string> parts;
                std::stringstream partStream(token);
                std::string part;
                while (std::getline(partStream, part, ':'))
                {
                    // trim spaces
                    part.erase(0, part.find_first_not_of(" \t"));
                    part.erase(part.find_last_not_of(" \t") + 1);
                    parts.push_back(part);
                }

                if (parts.size() >= 2 && parts[0] == "i3c")
                {
                    try
                    {
                        debugLevel = std::stoi(parts[1]);
                        foundI3C = true;
                        mctpPrInfo("I3C Debug Level: %d", debugLevel);
                        if (parts.size() >= 3)
                        {
                            // eid = std::stoi(parts[2]);
                            auto eid =
                                static_cast<uint8_t>(std::stoi(parts[2]));
                            mctpPrInfo("I3C Debug Eid: %d", eid);
                            setDebugEid(eid);
                        }
                        else
                        {
                            setDebugEid(0); // Reset EID if not provided
                        }
                    }
                    catch (...)
                    {
                        mctpPrErr(
                            "I3C debug level or EID is not an integer in debug file");
                        return;
                    }
                }
            }
        }

        if (foundI3C)
        {
            mctpPrInfo("MCTP I3C App Debug Level changes detected...");
            if (debugLevel >= 0)
                mctpSetLogStdio(debugLevel);
        }
        else
        {
            mctpPrErr("No I3C debug level found in debug file");
        }
    }

  private:
    void asyncWaitForEvents()
    {
        if (!descriptor || inotifyFd < 0)
            return;

        descriptor->async_wait(boost::asio::posix::stream_descriptor::wait_read,
                               [this](const boost::system::error_code& ec) {
                                   handleInotifyEvent(ec);
                               });
    }

    void handleInotifyEvent(const boost::system::error_code& ec)
    {
        if (ec)
        {
            if (ec != boost::asio::error::operation_aborted)
            {
                mctpPrErr("Inotify error: %s", ec.message().c_str());
            }
            return;
        }

        const size_t BUFFER_SIZE = 4096;
        char buffer[BUFFER_SIZE]
            __attribute__((aligned(__alignof__(struct inotify_event))));

        ssize_t length = read(inotifyFd, buffer, BUFFER_SIZE);

        if (length > 0)
        {
            processInotifyEvents(buffer, length);
        }

        // Re-arm async read
        asyncWaitForEvents();
    }

    void processInotifyEvents(char* buffer, ssize_t length)
    {
        const struct inotify_event* event;

        for (char* ptr = buffer; ptr < buffer + length;
             ptr += sizeof(struct inotify_event) + event->len)
        {
            event = reinterpret_cast<const struct inotify_event*>(ptr);

            if (event->len == 0)
                continue;

            std::string modifiedFile(event->name);

            // Only process watched file
            if (modifiedFile != fileName)
                continue;

            if (event->mask & (IN_CREATE | IN_MOVED_TO | IN_MODIFY))
            {
                std::string filePath = directoryPath + "/" + modifiedFile;
                readDebugFile(filePath);
            }
            else if (event->mask & (IN_DELETE | IN_MOVED_FROM))
            {
                mctpPrInfo("Debug file deleted, resetting to default logging");
                mctpSetLogStdio(MCTP_LOG_WARNING);
                setDebugEid(0); // Reset EID on file deletion
            }
        }
    }

    boost::asio::io_context& io;
    std::string directoryPath;
    std::string fileName;
    int inotifyFd;
    int watchDescriptor;
    std::unique_ptr<stream_descriptor> descriptor;
};

// Function declarations for debug file monitoring
int initDebugMonitor(boost::asio::io_context& io);
void cleanupDebugMonitor();
