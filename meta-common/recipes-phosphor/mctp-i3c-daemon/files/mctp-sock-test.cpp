
#include <sys/socket.h>
#include <sys/un.h>
#include <unistd.h>

#include <boost/asio.hpp>
#include <boost/asio/posix/stream_descriptor.hpp>

#include <iostream>
#include <memory>
#include <vector>

#define CLIENT_HEADER_SIZE 2

using namespace boost::asio;
namespace posix = boost::asio::posix;

struct client
{
    int sock;
    uint8_t type;
    bool active;
    uint8_t* buf;
    size_t bufSize;
    std::unique_ptr<posix::stream_descriptor> stream;
};

std::vector<client> clients;
io_context io;

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
        printf("Client %d disconnected\n", fd);
    }
}

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

int sendClientMsg(uint8_t eid, void* msg, size_t len, uint8_t type)
{
    struct iovec iov[2];
    struct msghdr msghdr;
    int rc;
    uint8_t tag_eid[2] = {0x00, eid};

    if (len < 2)
        return -1;

    printf("MCTP message received: len %zd, type %d\n", len, type);

    memset(&msghdr, 0, sizeof(msghdr));
    msghdr.msg_iov = iov;
    msghdr.msg_iovlen = 2;
    iov[0].iov_base = tag_eid;
    iov[0].iov_len = 2;
    iov[1].iov_base = msg;
    iov[1].iov_len = len;

    printf("get the client based on type %d\n", type);
    struct client* cli = getClientFromType(type);
    if (!cli) // Error condition check (client not found)
    {
        printf("Client with sock 0x%x not found\n", type);
        return -1; // Early return to handle the error condition
    }

    rc = sendmsg(cli->sock, &msghdr, 0);

    printf("sent response back to client of type %d\n", type);

    if (errno != EAGAIN && rc != (ssize_t)(len + 2))
    {
        printf("sendmsg failed for client %d: %s\n", cli->sock,
               strerror(errno));
        cli->active = false;
    }
    return 0;
}

// --------------------------------------------------------------------
// Helper to accept clients asynchronously
// --------------------------------------------------------------------
void asyncAcceptClient(std::unique_ptr<posix::stream_descriptor>& serverSock);

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
                    fprintf(stderr, "[%s] cli[%d] registered for type %u",
                            __func__, cli.sock, cli.type);
                    fprintf(stderr, "[%s] Set client %d type to %u\n", __func__,
                            cli.sock, cli.type);
                    goto read_next;
                }

                if (len < CLIENT_HEADER_SIZE)
                {
                    printf("Client message too short\n");
                    goto read_next;
                }

                uint8_t eid = cli.buf[1];
                size_t payload_len = len - CLIENT_HEADER_SIZE;
                // sendRecvMctpMsg(eid, cli.buf.data() + CLIENT_HEADER_SIZE,
                // payload_len, cli.type);
                printf("Read data:\n");
                for (size_t i = 0; i < payload_len; ++i)
                {
                    printf("%02X ", cli.buf[CLIENT_HEADER_SIZE + i]);
                }
                printf("\n");

                // echo response to client
                sendClientMsg(eid, cli.buf, len, cli.type);
            }

        read_next:
            // Continue reading next message
            handleClientRead(cli);
        });
}

// --------------------------------------------------------------------
// Accept handler
// --------------------------------------------------------------------
void acceptHandler(const boost::system::error_code& ec,
                   std::unique_ptr<posix::stream_descriptor>& serverSock)
{
    if (ec)
    {
        printf("Error on async_wait: %s", ec.message().c_str());
        return;
    }

    int client_fd = accept(serverSock->native_handle(), nullptr, nullptr);
    if (client_fd < 0)
    {
        perror("accept");
        asyncAcceptClient(serverSock);
        return;
    }

    struct client c;
    c.sock = client_fd;
    c.type = 0xFF;
    c.active = true;
    c.bufSize = 4096;
    c.stream = std::make_unique<posix::stream_descriptor>(io, client_fd);
    c.buf = static_cast<uint8_t*>(malloc(c.bufSize));

    if (!c.buf)
    {
        printf("Failed to allocate buffer for client %d\n", client_fd);
        close(client_fd);
        asyncAcceptClient(serverSock);
        return;
    }

    printf("Client %d connected\n", client_fd);

    clients.push_back(std::move(c));
    handleClientRead(clients.back());

    // Continue waiting for new connections
    asyncAcceptClient(serverSock);
}

// --------------------------------------------------------------------
// Setup async wait on the listening socket
// --------------------------------------------------------------------
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
int socket_init_unix()
{
    const char* sockname = "/tmp/mctp-i3c-sock-mux";
    unlink(sockname);

    int sockfd = socket(AF_UNIX, SOCK_SEQPACKET, 0);
    if (sockfd < 0)
    {
        perror("socket");
        return -1;
    }

    struct sockaddr_un addr{};
    addr.sun_family = AF_UNIX;
    strncpy(addr.sun_path, sockname, sizeof(addr.sun_path) - 1);

    if (bind(sockfd, (struct sockaddr*)&addr, sizeof(addr)) < 0)
    {
        perror("bind");
        close(sockfd);
        return -1;
    }

    if (listen(sockfd, 5) < 0)
    {
        perror("listen");
        close(sockfd);
        return -1;
    }

    return sockfd;
}

// --------------------------------------------------------------------
// Main
// --------------------------------------------------------------------
int main()
{
    int server_fd = socket_init_unix();
    if (server_fd < 0)
    {
        std::cerr << "Failed to create socket\n";
        return 1;
    }

    auto serverSock = std::make_unique<posix::stream_descriptor>(io, server_fd);

    printf("Listening on /tmp/mctp-i3c-sock-mux...\n");

    asyncAcceptClient(serverSock);

    io.run(); // replaces sd_event_loop()
    cleanupClients();
    close(server_fd);

    return 0;
}
