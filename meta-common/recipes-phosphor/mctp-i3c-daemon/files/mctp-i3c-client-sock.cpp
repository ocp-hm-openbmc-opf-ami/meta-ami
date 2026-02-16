/**
 * @file mctp-i3c-client-sock.cpp
 * @brief MCTP I3C client socket handler implementation.
 *
 * Handles client connections, message routing, and communication with MCTP
 * devices.
 */
#include "mctp-i3c-client-sock.hpp"

#include "utils.hpp"

using namespace boost::asio;
namespace posix = boost::asio::posix;

/**
 * @brief List of connected clients.
 */
std::vector<client> clients;

/**
 * @brief Global Boost.Asio IO context (externally defined).
 */
extern io_context io;

extern int MCTP_I3C_NET;

/**
 * @brief Remove a client from the list and clean up resources.
 * @param fd Socket file descriptor of the client to remove.
 */
void removeClient(int fd)
{
    auto it = std::find_if(clients.begin(), clients.end(),
                           [fd](const client& c) { return c.sock == fd; });

    if (it != clients.end())
    {
        close(it->sock);
        if (it->buf)
        {
            free(it->buf);
            it->buf = nullptr;
            it->bufSize = 0;
        }
        clients.erase(it);
        mctpPrDebug("Client %d disconnected\n", fd);
    }
}

/**
 * @brief Clean up all clients and release their resources.
 */
void cleanupClients()
{
    for (auto& cli : clients)
    {
        if (cli.buf)
            free(cli.buf);
        close(cli.sock);
    }
    clients.clear();
}

/**
 * @brief Get a pointer to a client by socket descriptor.
 * @param sock Socket file descriptor to search for.
 * @return Pointer to client struct, or nullptr if not found.
 */
struct client* getClient(int sock)
{
    for (auto& cl : clients) // Use reference to avoid copying
    {
        if (cl.sock == sock)
        {
            return &cl; // Return pointer to the found client
        }
    }
    return nullptr; // Return nullptr if client not found
}

/**
 * @brief Get a pointer to a client by type.
 * @param type Type value to search for.
 * @return Pointer to client struct, or nullptr if not found.
 */
struct client* getClientFromType(uint8_t type)
{
    for (auto& cl : clients) // Use reference to avoid copying
    {
        if (cl.type == type)
        {
            return &cl; // Return pointer to the found client
        }
    }
    return nullptr; // Return nullptr if client not found
}

/**
 * @brief Send a message to a client based on type.
 * @param eid Endpoint ID.
 * @param msg Pointer to message data.
 * @param len Length of message data.
 * @param type Client type.
 * @return 0 on success, -1 on error.
 */
int sendClientMsg(uint8_t eid, void* msg, size_t len, uint8_t type)
{
    struct iovec iov[2];
    struct msghdr msgHdr;
    int rc;
    uint8_t tagEid[2] = {0x00, eid};

    if (len < 2)
        return -1;

    mctpPrDebug("MCTP message received: len %zd, type %d\n", len, type);

    memset(&msgHdr, 0, sizeof(msgHdr));
    msgHdr.msg_iov = iov;
    msgHdr.msg_iovlen = 2;
    iov[0].iov_base = tagEid;
    iov[0].iov_len = 2;
    iov[1].iov_base = msg;
    iov[1].iov_len = len;

    mctpPrDebug("get the client based on type %d\n", type);
    struct client* cli = getClientFromType(type);
    if (!cli) // Error condition check (client not found)
    {
        mctpPrErr("Client with sock 0x%x not found\n", type);
        return -1; // Early return to handle the error condition
    }

    rc = sendmsg(cli->sock, &msgHdr, 0);

    mctpPrDebug("sent response back to client of type %d\n", type);

    if (errno != EAGAIN && rc != (ssize_t)(len + 2))
    {
        mctpPrErr("sendmsg failed for client %d: %s\n", cli->sock,
                  strerror(errno));
        cli->active = false;
    }
    return 0;
}

// got messages from client send to mctp device
/**
 * @brief Send a message from client to MCTP device and forward response.
 * @param eid Endpoint ID.
 * @param buf Pointer to buffer to send.
 * @param bufSize Size of buffer.
 * @param type Message type.
 * @return 0 on success, -1 on error.
 */
int sendRecvMctpMsg(uint8_t eid, void* buf, ssize_t bufSize, uint8_t type)
{
    struct sockaddr_mctp addr;
    memset(&addr, 0, sizeof(addr)); // Zero out all fields

    // unsigned char *buf, *rxbuf;
    unsigned char* rxbuf;
    socklen_t addrlen;
    int sd;
    ssize_t rc;
    ssize_t msglen;

    sd = socket(AF_MCTP, SOCK_DGRAM, 0);
    if (sd < 0)
    {
        mctpPrErr("%s: socket failed ", __func__);
        return -1;
    }

    addrlen = sizeof(struct sockaddr_mctp);
    /* populate the remote address information */
    addr.smctp_family = AF_MCTP;  /* we're using the MCTP family */
    addr.smctp_addr.s_addr = eid; /* send to remote endpoint ID 8 */
    addr.smctp_network = MCTP_I3C_NET;
    addr.smctp_type = type; /* encapsulated protocol type (eg. PLDM = 1) */
    addr.smctp_tag = MCTP_TAG_OWNER; /* we own the tag, and so the kernel
                                        will allocate one for us */

    int ret_val = bind(sd, (struct sockaddr*)&addr, sizeof(addr));
    if (ret_val < 0)
    {
        mctpPrErr("%s: bind  failed ", __func__);
        close(sd);
        return -1;
    }

    /* send data */
    rc = sendto(sd, buf, bufSize, 0, (struct sockaddr*)&addr, addrlen);
    if (rc != bufSize)
    {
        mctpPrErr("%s: sendto failed for eid:%x", __func__, eid);
        close(sd);
        return -1;
    }

    rc = pollWithTimeout(sd, 5000); // 5 seconds timeout
    if (rc < 0)
    {
        mctpPrErr("%s: poll error", __func__);
        close(sd);
        return -1;
    }

    msglen = recvfrom(sd, NULL, 0, MSG_PEEK | MSG_TRUNC, NULL, 0);
    if (msglen < 0)
    {
        mctpPrErr("%s: recvfrom msg peek failed ", __func__);
        close(sd);
        return -1;
    }

    rxbuf = (unsigned char*)malloc(msglen);
    if (!rxbuf)
    {
        mctpPrErr("%s: malloc failed ", __func__);
        return -1;
    }

    /* receive response */
    rc = recvfrom(sd, rxbuf, msglen, MSG_TRUNC, (struct sockaddr*)&addr,
                  &addrlen);
    if (rc < 0)
    {
        mctpPrErr("%s: recvfrom  failed ", __func__);
        free(rxbuf);
        close(sd);
        return -1;
    }

    if (!(addrlen == sizeof(struct sockaddr_mctp)))
    {
        mctpPrErr("%s: unknown recv address length ", __func__);
        return -1;
    }

    mctpPrDebug("%s response data:", __func__);
    mctpPrDebug("------------- MCTP PACKET -----------------");
    for (int i = 0; i < msglen; i++)
        mctpPrDebugRaw("0x%02x ", rxbuf[i]);
    mctpPrDebugRaw("\n");
    mctpPrDebug("-------------------------------------------");

    // forward the response to client
    sendClientMsg(eid, rxbuf, msglen, addr.smctp_type);

    free(rxbuf);
    close(sd);
    return 0;
}

// --------------------------------------------------------------------
// Helper to accept clients asynchronously
// --------------------------------------------------------------------
/**
 * @brief Helper to accept clients asynchronously.
 * @param serverSock Server socket stream descriptor.
 */
void asyncAcceptClient(std::unique_ptr<posix::stream_descriptor>& serverSock);

/**
 * @brief Asynchronously read data from a client and process messages.
 * @param cli Reference to client struct.
 */
void handleClientRead(client& cli)
{
    if (!cli.active)
    {
        printf("Client %d inactive, not reading\n", cli.sock);
        return;
    }

    cli.stream->async_read_some(
        buffer(cli.buf, cli.bufSize),
        [&](boost::system::error_code ec, std::size_t len) {
            if (ec)
            {
                printf("Client %d read error: %s\n", cli.sock,
                       ec.message().c_str());
                removeClient(cli.sock);
                return;
            }

            if (len > 0)
            {
                /* are we waiting for a type message? */
                if (cli.type == 0xff)
                {
                    cli.type = cli.buf[0];
                    mctpPrDebug(" cli[%d] registered for type %u", cli.sock,
                                cli.type);
                    goto read_next;
                }

                if (len < CLIENT_HEADER_SIZE)
                {
                    printf("Client message too short\n");
                    goto read_next;
                }

                // forward the request to corresponding mctp device
                uint8_t eid = cli.buf[1];
                size_t payloadLen = len - CLIENT_HEADER_SIZE;
                sendRecvMctpMsg(eid, cli.buf + CLIENT_HEADER_SIZE, payloadLen,
                                cli.type);
                mctpPrDebug("Read data:\n");
                for (size_t i = 0; i < payloadLen; ++i)
                {
                    mctpPrDebug("%02X ", cli.buf[CLIENT_HEADER_SIZE + i]);
                }
                mctpPrDebug("\n");
            }

        read_next:
            // Continue reading next message
            handleClientRead(cli);
        });
}

// --------------------------------------------------------------------
// Accept handler
// --------------------------------------------------------------------
/**
 * @brief Handler for accepting new client connections.
 * @param ec Boost.Asio error code.
 * @param serverSock Server socket stream descriptor.
 */
void acceptHandler(const boost::system::error_code& ec,
                   std::unique_ptr<posix::stream_descriptor>& serverSock)
{
    if (ec)
    {
        printf("Error on async_wait: %s", ec.message().c_str());
        return;
    }

    int clientFd = accept(serverSock->native_handle(), nullptr, nullptr);
    if (clientFd < 0)
    {
        perror("accept");
        asyncAcceptClient(serverSock);
        return;
    }

    struct client c;
    c.sock = clientFd;
    c.type = 0xFF;
    c.active = true;
    c.bufSize = 4096;
    c.stream = std::make_unique<posix::stream_descriptor>(io, clientFd);
    c.buf = static_cast<uint8_t*>(malloc(c.bufSize));

    if (!c.buf)
    {
        printf("Failed to allocate buffer for client %d\n", clientFd);
        close(clientFd);
        asyncAcceptClient(serverSock);
        return;
    }

    printf("Client %d connected\n", clientFd);

    clients.push_back(std::move(c));
    handleClientRead(clients.back());

    // Continue waiting for new connections
    asyncAcceptClient(serverSock);
}

// --------------------------------------------------------------------
// Setup async wait on the listening socket
// --------------------------------------------------------------------
/**
 * @brief Setup async wait on the listening socket for new connections.
 * @param serverSock Server socket stream descriptor.
 */
void asyncAcceptClient(std::unique_ptr<posix::stream_descriptor>& serverSock)
{
    serverSock->async_wait(posix::stream_descriptor::wait_read,
                           [&](const boost::system::error_code& ec) {
                               acceptHandler(ec, serverSock);
                           });
}

// --------------------------------------------------------------------
// Initialize UNIX socket listener
// --------------------------------------------------------------------
/**
 * @brief Initialize UNIX socket listener for client connections.
 * @param sockfd Reference to socket file descriptor to initialize.
 * @return Socket file descriptor on success, -1 on error.
 */
int ClientSocketInit(int& sockFd)
{
    const char* sockName = "/tmp/mctp-i3c-sock-mux";
    unlink(sockName);

    sockFd = socket(AF_UNIX, SOCK_SEQPACKET, 0);
    if (sockFd < 0)
    {
        mctpPrErr("client socket error");
        return -1;
    }

    struct sockaddr_un addr{};
    addr.sun_family = AF_UNIX;
    strncpy(addr.sun_path, sockName, sizeof(addr.sun_path) - 1);

    if (bind(sockFd, (struct sockaddr*)&addr, sizeof(addr)) < 0)
    {
        mctpPrErr("client bind error");
        close(sockFd);
        return -1;
    }

    if (listen(sockFd, 5) < 0)
    {
        mctpPrErr("client listen error");
        close(sockFd);
        return -1;
    }

    return 1;
}
