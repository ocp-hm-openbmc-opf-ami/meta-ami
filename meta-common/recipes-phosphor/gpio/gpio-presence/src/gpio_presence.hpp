#pragma once

#include <syslog.h>

#include <boost/algorithm/string/replace.hpp>
#include <boost/asio/io_context.hpp>
#include <boost/asio/posix/stream_descriptor.hpp>
#include <boost/asio/steady_timer.hpp>
#include <boost/container/flat_map.hpp>
#include <boost/type_index.hpp>
#include <gpiod.hpp>
#include <sdbusplus/asio/connection.hpp>
#include <sdbusplus/asio/object_server.hpp>
#include <sdbusplus/message/types.hpp>

#include <algorithm>
#include <chrono>
#include <iostream>
#include <map>
#include <memory>
#include <string>
#include <variant>
#include <vector>

class gpioPresence : public std::enable_shared_from_this<gpioPresence>
{
  public:
    gpioPresence(sdbusplus::asio::object_server& objectServer,
                 std::shared_ptr<sdbusplus::asio::connection>& conn,
                 boost::asio::io_context& io, const std::string& gpioName,
                 const std::string& lineName);

    bool getGpioData(
        std::shared_ptr<sdbusplus::asio::connection>& conn,
        const std::string& lineName, gpiod::line& gpioLine,
        boost::asio::posix::stream_descriptor& gpioEventDescriptor);

    void monitor(std::shared_ptr<sdbusplus::asio::connection>& conn,
                 boost::asio::posix::stream_descriptor& event,
                 gpiod::line& line);

    ~gpioPresence();

    std::string gpio;

  private:
    sdbusplus::asio::object_server& objServer;
    gpiod::line procPresentLine;
    boost::asio::posix::stream_descriptor procPresentEvent;
    bool dbus;
    boost::asio::steady_timer waitTimer;
    std::shared_ptr<sdbusplus::asio::connection>& conn;
    std::shared_ptr<sdbusplus::asio::dbus_interface> gpioInterface;
};

gpioPresence::gpioPresence(sdbusplus::asio::object_server& objectServer,
                           std::shared_ptr<sdbusplus::asio::connection>& conn,
                           boost::asio::io_context& io,
                           const std::string& gpioName,
                           const std::string& lineName) :
    gpio(lineName), objServer(objectServer), procPresentEvent(io),
    waitTimer(io), conn(conn)
{
    gpioInterface =
        objectServer.add_interface("/xyz/openbmc_project/gpio/" + gpioName,
                                   "xyz.openbmc_project.gpio.info");

    uint8_t state = 0;
    gpioInterface->register_property("Value", state);

    if (!gpioInterface->initialize())
    {
        std::cerr << "gpio-presence failed to initialize gpio interface"
                  << "\n";
    }

    getGpioData(conn, lineName, procPresentLine, procPresentEvent);
}

gpioPresence::~gpioPresence()
{
    objServer.remove_interface(gpioInterface);
}

bool gpioPresence::getGpioData(
    std::shared_ptr<sdbusplus::asio::connection>& conn,
    const std::string& procGpioName, gpiod::line& gpioLine,
    boost::asio::posix::stream_descriptor& gpioEventDescriptor)
{
    // Find the GPIO line
    gpioLine = gpiod::find_line(procGpioName);
    if (!gpioLine)
    {
        std::cerr << "Failed to find the line\n";
        return false;
    }

    try
    {
        gpioLine.request(
            {"gpio-presence", gpiod::line_request::EVENT_BOTH_EDGES, 0});
    }
    catch (std::exception&)
    {
        std::cerr << "Failed to request event, " << procGpioName
                  << " is currently busy!!\n";
        if (gpioInterface)
        {
            objServer.remove_interface(gpioInterface);
            gpioInterface = nullptr;
        }
        return false;
    }

    int gpioLineFd = gpioLine.event_get_fd();
    if (gpioLineFd < 0)
    {
        std::cerr << "Failed to get fd\n";
        return false;
    }
    gpioEventDescriptor.assign(gpioLineFd);

    gpioInterface->set_property("Value",
                                static_cast<uint8_t>(gpioLine.get_value()));

    monitor(conn, gpioEventDescriptor, gpioLine);

    return true;
}

void gpioPresence::monitor(std::shared_ptr<sdbusplus::asio::connection>& conn,
                           boost::asio::posix::stream_descriptor& event,
                           gpiod::line& line)
{
    event.async_wait(
        boost::asio::posix::stream_descriptor::wait_read,
        [this, &conn, &event, &line](const boost::system::error_code ec) {
            if (ec)
            {
                std::cerr << " fd handler error: " << ec.message() << "\n";
                return;
            }
            gpiod::line_event lineEvent = line.event_read();
            if ((lineEvent.event_type == gpiod::line_event::FALLING_EDGE) ||
                (lineEvent.event_type == gpiod::line_event::RISING_EDGE))
            {
                gpioInterface->set_property(
                    "Value", static_cast<uint8_t>(line.get_value()));
            }

            monitor(conn, event, line);
        });
}
