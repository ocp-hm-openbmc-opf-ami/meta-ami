/**
 * @brief MCTP requester utility
 *
 * A simple C++ implementation for sending MCTP requests and receiving
 * responses.
 */

#include <linux/mctp.h>
#include <sys/socket.h>
#include <unistd.h>

#include <algorithm>
#include <cstdint>
#include <cstdlib>
#include <cstring>
#include <iomanip>
#include <iostream>
#include <string>
#include <vector>

// Extended MCTP addressing support
#ifndef SOL_MCTP
#define SOL_MCTP 285
#endif

#ifndef MCTP_OPT_ADDR_EXT
#define MCTP_OPT_ADDR_EXT 1
#endif

using mctp_eid_t = std::uint8_t;

constexpr int DEFAULT_NET = 1;
constexpr mctp_eid_t DEFAULT_EID = 8;
constexpr std::size_t DEFAULT_LEN = 1;

/**
 * @brief Parse colon-separated hex bytes string
 * @param input Input string with hex bytes separated by colons
 * @param output Output vector to store parsed bytes
 * @return true on success, false on failure
 */
bool parseHexAddress(const std::string& input,
                     std::vector<std::uint8_t>& output)
{
    output.clear();
    std::size_t pos = 0;

    while (pos < input.length())
    {
        if (input[pos] == ':')
        {
            if (pos == 0 || pos == input.length() - 1 || output.empty())
            {
                return false; // Invalid colon placement
            }
            ++pos;
            continue;
        }

        try
        {
            std::size_t endPos;
            unsigned long value = std::stoul(input.substr(pos), &endPos, 16);

            if (endPos == 0 || value > 0xFF)
            {
                return false; // Invalid hex byte
            }

            output.push_back(static_cast<std::uint8_t>(value));
            pos += endPos;

            if (pos < input.length() && input[pos] != ':')
            {
                return false; // Expected colon separator
            }
        }
        catch (...)
        {
            return false;
        }
    }

    return true;
}

/**
 * @brief Send MCTP request and receive response
 */
int mctpRequest(unsigned int net, mctp_eid_t eid, unsigned int ifindex,
                const std::vector<std::uint8_t>& lladdr, std::uint8_t type,
                const std::vector<std::uint8_t>& data, std::size_t len)
{
    // Create socket
    int sd = socket(AF_MCTP, SOCK_DGRAM, 0);
    if (sd < 0)
    {
        std::cerr << "Failed to create socket" << std::endl;
        return EXIT_FAILURE;
    }

    // Setup address structure
    socklen_t addrlen;
    struct sockaddr_mctp addr{};
    struct sockaddr_mctp_ext ext_addr{};
    struct sockaddr* addr_ptr;

    // Handle extended addressing if needed
    if (!lladdr.empty() && ifindex > 0)
    {
        // Use extended addressing
        std::memset(&ext_addr, 0, sizeof(ext_addr));

        // Set base address fields
        ext_addr.smctp_base.smctp_family = AF_MCTP;
        ext_addr.smctp_base.smctp_network = net;
        ext_addr.smctp_base.smctp_addr.s_addr = eid;
        ext_addr.smctp_base.smctp_type = type;
        ext_addr.smctp_base.smctp_tag = MCTP_TAG_OWNER;

        // Set extended address fields
        ext_addr.smctp_ifindex = static_cast<int>(ifindex);
        ext_addr.smctp_halen = static_cast<std::uint8_t>(
            std::min(lladdr.size(), sizeof(ext_addr.smctp_haddr)));
        std::memcpy(ext_addr.smctp_haddr, lladdr.data(), ext_addr.smctp_halen);

        addr_ptr = reinterpret_cast<struct sockaddr*>(&ext_addr);
        addrlen = sizeof(struct sockaddr_mctp_ext);

        // Enable extended addressing
        int val = 1;
        int rc = setsockopt(sd, SOL_MCTP, MCTP_OPT_ADDR_EXT, &val, sizeof(val));
        if (rc < 0)
        {
            std::cerr << "Kernel does not support MCTP extended addressing"
                      << std::endl;
            close(sd);
            return EXIT_FAILURE;
        }

        std::cout << "Sending to (net " << net << ", eid "
                  << static_cast<int>(eid) << ", ifindex " << ifindex
                  << ", lladdr ";
        for (std::size_t i = 0; i < lladdr.size(); ++i)
        {
            if (i > 0)
                std::cout << ":";
            std::cout << std::hex << std::setw(2) << std::setfill('0')
                      << static_cast<int>(lladdr[i]);
        }
        std::cout << std::dec << "), type " << static_cast<int>(type)
                  << ", len " << len << std::endl;
    }
    else
    {
        // Use basic addressing
        addr.smctp_family = AF_MCTP;
        addr.smctp_network = net;
        addr.smctp_addr.s_addr = eid;
        addr.smctp_type = type;
        addr.smctp_tag = MCTP_TAG_OWNER;

        addr_ptr = reinterpret_cast<struct sockaddr*>(&addr);
        addrlen = sizeof(struct sockaddr_mctp);

        std::cout << "Sending to (net " << net << ", eid "
                  << static_cast<int>(eid) << "), type "
                  << static_cast<int>(type) << ", len " << len << std::endl;
    }

    // Prepare send buffer
    std::vector<std::uint8_t> sendBuffer;
    if (!data.empty())
    {
        sendBuffer = data;
    }
    else
    {
        sendBuffer.resize(len);
        for (std::size_t i = 0; i < len; ++i)
        {
            sendBuffer[i] = static_cast<std::uint8_t>(i & 0xFF);
        }
    }

    // Send data
    ssize_t sent =
        sendto(sd, sendBuffer.data(), sendBuffer.size(), 0, addr_ptr, addrlen);
    if (sent != static_cast<ssize_t>(sendBuffer.size()))
    {
        std::cerr << "Failed to send complete message" << std::endl;
        close(sd);
        return EXIT_FAILURE;
    }

    // Get response size
    ssize_t responseSize =
        recvfrom(sd, nullptr, 0, MSG_PEEK | MSG_TRUNC, nullptr, 0);
    if (responseSize < 0)
    {
        std::cerr << "Failed to peek response size" << std::endl;
        close(sd);
        return EXIT_FAILURE;
    }

    // Receive response
    std::vector<std::uint8_t> responseBuffer(
        static_cast<std::size_t>(responseSize));

    // Use appropriate address structure for receive
    struct sockaddr_mctp recv_addr{};
    socklen_t recv_addrlen = sizeof(recv_addr);

    ssize_t received =
        recvfrom(sd, responseBuffer.data(), responseBuffer.size(), MSG_TRUNC,
                 reinterpret_cast<struct sockaddr*>(&recv_addr), &recv_addrlen);
    if (received < 0)
    {
        std::cerr << "Failed to receive response" << std::endl;
        close(sd);
        return EXIT_FAILURE;
    }

    close(sd);

    // Validate address length
    if (recv_addrlen != sizeof(struct sockaddr_mctp))
    {
        std::cerr << "Unexpected response address length: " << recv_addrlen
                  << std::endl;
        // Continue anyway as this might still work
    }

    // Display response information
    std::cout << "Response from (net " << recv_addr.smctp_network << ", eid "
              << static_cast<int>(recv_addr.smctp_addr.s_addr) << ") type "
              << static_cast<int>(recv_addr.smctp_type) << " len " << received
              << std::endl;

    // Display response data
    std::cout << "Data:" << std::endl;
    for (std::size_t i = 0; i < responseBuffer.size(); ++i)
    {
        std::cout << "0x" << std::hex << std::setw(2) << std::setfill('0')
                  << static_cast<int>(responseBuffer[i]) << " ";
        if ((i + 1) % 16 == 0)
            std::cout << std::endl; // New line every 16 bytes
    }
    std::cout << std::dec << std::endl;

    return 0;
}

void printUsage()
{
    std::cerr << "Usage: mctp-req [eid <eid>] [net <net>] "
                 "[ifindex <ifindex> lladdr <hwaddr>] [type <type>] "
                 "[len <len>] [data <data>]"
              << std::endl;
    std::cerr << "Defaults: eid " << static_cast<int>(DEFAULT_EID) << ", net "
              << DEFAULT_NET << ", len " << DEFAULT_LEN << std::endl;
    std::cerr << "Data format: colon-separated hex bytes (e.g., 00:01:0f)"
              << std::endl;
    std::cerr
        << "Extended addressing: Use ifindex and lladdr together for interface-specific routing"
        << std::endl;
    std::cerr << "                     ifindex: network interface index"
              << std::endl;
    std::cerr
        << "                     lladdr: link-layer address in hex format (e.g., 01:23:45)"
        << std::endl;
}

int main(int argc, char* argv[])
{
    try
    {
        if (argc % 2 == 0)
        {
            std::cerr << "Extra argument: " << argv[argc - 1] << std::endl;
            printUsage();
            return 255;
        }

        // Default values
        unsigned int net = DEFAULT_NET;
        mctp_eid_t eid = DEFAULT_EID;
        std::size_t len = DEFAULT_LEN;
        std::uint8_t type = 1;
        unsigned int ifindex = 0;
        std::vector<std::uint8_t> data;
        std::vector<std::uint8_t> lladdr;

        // Parse command line arguments
        for (int i = 1; i < argc; i += 2)
        {
            std::string optname = argv[i];
            std::string optval = argv[i + 1];

            if (optname == "eid")
            {
                unsigned long tmp = std::stoul(optval, nullptr, 0);
                if (tmp > 0xFF)
                {
                    std::cerr << "Invalid EID value: " << tmp << std::endl;
                    return EXIT_FAILURE;
                }
                eid = static_cast<mctp_eid_t>(tmp);
            }
            else if (optname == "net")
            {
                unsigned long tmp = std::stoul(optval, nullptr, 0);
                if (tmp > 0xFF)
                {
                    std::cerr << "Invalid network value: " << tmp << std::endl;
                    return EXIT_FAILURE;
                }
                net = static_cast<unsigned int>(tmp);
            }
            else if (optname == "ifindex")
            {
                ifindex = std::stoul(optval, nullptr, 0);
            }
            else if (optname == "len")
            {
                unsigned long tmp = std::stoul(optval, nullptr, 0);
                if (tmp > 64 * 1024)
                {
                    std::cerr << "Length too large: " << tmp << std::endl;
                    return EXIT_FAILURE;
                }
                len = static_cast<std::size_t>(tmp);
            }
            else if (optname == "type")
            {
                unsigned long tmp = std::stoul(optval, nullptr, 0);
                if (tmp > 0xFF)
                {
                    std::cerr << "Invalid type value: " << tmp << std::endl;
                    return EXIT_FAILURE;
                }
                type = static_cast<std::uint8_t>(tmp);
            }
            else if (optname == "data")
            {
                if (!parseHexAddress(optval, data))
                {
                    std::cerr << "Invalid data format: " << optval << std::endl;
                    return EXIT_FAILURE;
                }
                len = data.size();
            }
            else if (optname == "lladdr")
            {
                if (!parseHexAddress(optval, lladdr))
                {
                    std::cerr
                        << "Invalid lladdr format: " << optval << std::endl;
                    return EXIT_FAILURE;
                }
            }
            else
            {
                std::cerr << "Unknown argument: " << optname << std::endl;
                printUsage();
                return EXIT_FAILURE;
            }
        }

        return mctpRequest(net, eid, ifindex, lladdr, type, data, len);
    }
    catch (const std::exception& e)
    {
        std::cerr << "Error: " << e.what() << std::endl;
        printUsage();
        return EXIT_FAILURE;
    }
}
