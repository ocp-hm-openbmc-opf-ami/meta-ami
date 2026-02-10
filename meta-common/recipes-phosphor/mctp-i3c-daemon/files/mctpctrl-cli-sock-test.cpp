

#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/socket.h>
#include <sys/un.h>
#include <unistd.h>

#include <cstdint>

#define SOCKET_PATH "/tmp/mctp-i3c-sock-mux"

struct mctp_ctrl_cmd_get_uuid
{
    uint8_t rq_dgram_inst;
    uint8_t command_code;
};

int main()
{
    int sockfd;
    struct sockaddr_un addr;
    const uint8_t mctp_type = 0x00; // e.g., MCTP_CTRL
    const uint8_t dest_eid = 0x1D;
    const uint8_t tag = 0x00;

    // Create socket
    sockfd = socket(AF_UNIX, SOCK_SEQPACKET, 0);
    if (sockfd < 0)
    {
        perror("socket");
        return 1;
    }

    memset(&addr, 0, sizeof(addr));
    addr.sun_family = AF_UNIX;
    strncpy(addr.sun_path, SOCKET_PATH, sizeof(addr.sun_path) - 1);
    // memcpy(addr.sun_path, SOCKET_PATH, sizeof(addr.sun_path) - 1);

    if (connect(sockfd, (struct sockaddr*)&addr, sizeof(addr)) < 0)
    {
        perror("connect");
        close(sockfd);
        return 1;
    }

    printf("Connected to server socket\n");

    // Step 1: Send message type
    if (write(sockfd, &mctp_type, 1) != 1)
    {
        perror("write type");
        close(sockfd);
        return 1;
    }

    printf("Sent MCTP message type: %u\n", mctp_type);

    uint8_t hdr[2] = {tag, dest_eid};
    struct mctp_ctrl_cmd_get_uuid get_uuid;
    get_uuid.rq_dgram_inst = 0x80;
    get_uuid.command_code = 0x03;

    struct iovec iov[2];
    iov[0].iov_base = hdr;
    iov[0].iov_len = sizeof(hdr);
    iov[1].iov_base = (uint8_t*)&get_uuid;
    iov[1].iov_len = sizeof(get_uuid);

    struct msghdr msg;
    memset(&msg, 0, sizeof(msg));
    msg.msg_iov = iov;
    msg.msg_iovlen = sizeof(iov) / sizeof(iov[0]);

    // Step 2: Send payload (includes EID at byte offset 1)
    ssize_t ret = sendmsg(sockfd, &msg, 0);
    if (ret == -1)
    {
        perror("write payload");
        close(sockfd);
        return 1;
    }

    printf("Sent payload to EID 0x%02x\n", dest_eid);

    // Step 3: Receive response
    uint8_t recvbuf[512];
    ssize_t len = recv(sockfd, recvbuf, sizeof(recvbuf), 0);
    if (len > 0)
    {
        printf("Received response (%zd bytes): ", len);
        for (ssize_t i = 0; i < len; ++i)
            printf("%02x ", recvbuf[i]);
        printf("\n");
    }
    else
    {
        printf("No response or error: %s\n", strerror(errno));
    }

    close(sockfd);
    return 0;
}
