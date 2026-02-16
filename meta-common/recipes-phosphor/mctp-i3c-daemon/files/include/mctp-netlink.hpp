#ifndef __MCTP_NETLINK_H__
#define __MCTP_NETLINK_H__

#include <errno.h>
#include <linux/rtnetlink.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/socket.h>
#include <unistd.h>

#include <cstdint>

#define BUF_SIZE 8192
#define INTF_UP 0x01

int mctpAddrAdd(uint8_t eid, int index);
int mctpAddrDel(uint8_t eid, int index);
int mctpLinkSet(int index);
int mctpLinkSetNet(int index, uint32_t net);
int mctpRouteDel(uint8_t routeEid, int index);
int mctpNeighDel(uint8_t routeEid, const char* lladdrStr, int index);

int addMctpRouteAndNeigh(uint8_t routeEid, const char* lladdrStr, int index);

#endif /* __MCTP_NETLINK_H__ */
