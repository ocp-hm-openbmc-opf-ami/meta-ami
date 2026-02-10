#ifndef __MCTP_I3C_CLIENT_SOCK_H__
#define __MCTP_I3C_CLIENT_SOCK_H__
#include "mctp-app-log.hpp"
#include "mctp-ctrl-cmds.hpp"

#include <sys/socket.h>
#include <sys/un.h>
#include <unistd.h>

#include <boost/asio.hpp>
#include <boost/asio/posix/stream_descriptor.hpp>

#include <algorithm>
#include <cerrno>
#include <cstdint>
#include <memory>

#define CLIENT_HEADER_SIZE 2

struct client
{
    int sock;
    uint8_t type;
    bool active;
    uint8_t* buf;
    size_t bufSize;
    std::unique_ptr<boost::asio::posix::stream_descriptor> stream;
};
int ClientSocketInit(int& sockfd);
void acceptHandler(
    const boost::system::error_code& ec,
    std::unique_ptr<boost::asio::posix::stream_descriptor>& serverSock);
int sendClientMsg(uint8_t eid, void* msg, size_t len, uint8_t type);
void cleanupClients();

#endif /* __MCTP_I3C_CLIENT_SOCK_H__ */
