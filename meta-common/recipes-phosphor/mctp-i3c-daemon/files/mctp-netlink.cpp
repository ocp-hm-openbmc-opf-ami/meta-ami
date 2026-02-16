#include "mctp-netlink.hpp"

#include "mctp-app-log.hpp"

#define PID_SIZE 6

/**
 * @brief Put a netlink attribute and advance the pointer
 * @param prta Pointer to rtattr pointer (will be advanced)
 * @param rtaLen Pointer to remaining length (will be decremented)
 * @param type Attribute type
 * @param value Pointer to attribute value
 * @param valLen Length of the value
 * @return Size of space used by the attribute
 */
static size_t mctpPutRtnlmsgAttr(struct rtattr** prta, size_t* rtaLen,
                                 unsigned short type, const void* value,
                                 size_t valLen)
{
    struct rtattr* rta = *prta;

    rta->rta_type = type;
    rta->rta_len = RTA_LENGTH(valLen);
    memcpy(RTA_DATA(rta), value, valLen);

    size_t space = RTA_SPACE(valLen);
    *prta = RTA_NEXT(rta, *rtaLen);
    *rtaLen -= space;

    return space;
}

/**
 * @brief Check whether a route for the given route_eid exists
 * @param addrEid EID to check for address existence
 * @return 1 if address exists, 0 if not found, -1 on error
 */
int mctpAddrExists(uint8_t addrEid)
{
    int sock;
    struct sockaddr_nl sa;
    char buf[BUF_SIZE];
    struct nlmsghdr* nh;
    int len, ret;

    /// Create netlink socket.
    sock = socket(AF_NETLINK, SOCK_RAW, NETLINK_ROUTE);
    if (sock < 0)
    {
        mctpPrErr("socket");
        return -1;
    }

    memset(&sa, 0, sizeof(sa));
    sa.nl_family = AF_NETLINK;
    sa.nl_pid = 0;

    if (bind(sock, (struct sockaddr*)&sa, sizeof(sa)) < 0)
    {
        mctpPrErr("bind");
        close(sock);
        return -1;
    }

    /// Prepare a dump request for addresses.
    struct
    {
        struct nlmsghdr nh;
        struct ifaddrmsg ifa;
    } req;
    memset(&req, 0, sizeof(req));
    req.nh.nlmsg_len = NLMSG_LENGTH(sizeof(struct ifaddrmsg));
    req.nh.nlmsg_type = RTM_GETADDR;
    req.nh.nlmsg_flags = NLM_F_REQUEST | NLM_F_DUMP;
    req.nh.nlmsg_seq = 1;
    req.nh.nlmsg_pid = getpid();
    req.ifa.ifa_family = AF_MCTP; /// use AF_MCTP to filter MCTP addresses

    ret = send(sock, &req, req.nh.nlmsg_len, 0);
    if (ret < 0)
    {
        mctpPrErr("send");
        close(sock);
        return -1;
    }

    if (ret != (int)req.nh.nlmsg_len)
    {
        mctpPrErr(" %s: sendto: short (send %d, expected %d )", __func__, ret,
                  req.nh.nlmsg_len);
        close(sock);
        return -1;
    }

    /// Loop to read all responses.
    while ((len = recv(sock, buf, sizeof(buf), 0)) > 0)
    {
        for (nh = (struct nlmsghdr*)buf; NLMSG_OK(nh, len);
             nh = NLMSG_NEXT(nh, len))
        {
            if (nh->nlmsg_type == NLMSG_DONE)
                goto done;
            if (nh->nlmsg_type == NLMSG_ERROR)
            {
                mctpPrErr("Netlink error in address dump");
                close(sock);
                return -1;
            }

            struct ifaddrmsg* ifa = (struct ifaddrmsg*)NLMSG_DATA(nh);
            int attrlen = IFA_PAYLOAD(nh);
            struct rtattr* attr;

            /// Walk through attributes
            for (attr = IFA_RTA(ifa); RTA_OK(attr, attrlen);
                 attr = RTA_NEXT(attr, attrlen))
            {
                if (attr->rta_type == IFA_LOCAL)
                {
                    /// Assume our address is a single byte (the EID)
                    uint8_t localEid;
                    memcpy(&localEid, RTA_DATA(attr), sizeof(localEid));
                    if (localEid == addrEid)
                    {
                        close(sock);
                        return 1; /// address exists
                    }
                }
            }
        }
    }

done:
    close(sock);
    return 0; /// address not found
}

/**
 * @brief Check whether a route for the given routeEid exists
 * @param routeEid EID to check for route existence
 * @return 1 if route exists, 0 if not found, -1 on error
 */
int mctpRouteExists(uint8_t routeEid)
{
    int sock;
    struct sockaddr_nl sa;
    char buf[BUF_SIZE];
    struct nlmsghdr* nh;
    int len, ret;

    /// Create netlink socket.
    sock = socket(AF_NETLINK, SOCK_RAW, NETLINK_ROUTE);
    if (sock < 0)
    {
        mctpPrErr("socket");
        return -1;
    }

    memset(&sa, 0, sizeof(sa));
    sa.nl_family = AF_NETLINK;
    sa.nl_pid = 0;

    if (bind(sock, (struct sockaddr*)&sa, sizeof(sa)) < 0)
    {
        mctpPrErr("bind");
        close(sock);
        return -1;
    }

    /// Prepare a dump request for routes.
    struct
    {
        struct nlmsghdr nh;
        struct rtgenmsg rt;
    } req;
    memset(&req, 0, sizeof(req));
    req.nh.nlmsg_len = NLMSG_LENGTH(sizeof(struct rtgenmsg));
    req.nh.nlmsg_type = RTM_GETROUTE;
    req.nh.nlmsg_flags = NLM_F_REQUEST | NLM_F_DUMP;
    req.nh.nlmsg_seq = 1;
    req.nh.nlmsg_pid = getpid();
    req.rt.rtgen_family = AF_MCTP; /// use AF_MCTP to filter MCTP routes

    ret = send(sock, &req, req.nh.nlmsg_len, 0);
    if (ret < 0)
    {
        mctpPrErr("send");
        close(sock);
        return -1;
    }

    if (ret != (int)req.nh.nlmsg_len)
    {
        mctpPrErr(" %s: sendto: short (send %d, expected %d )", __func__, ret,
                  req.nh.nlmsg_len);
        close(sock);
        return -1;
    }

    /// Loop to read all responses.
    while ((len = recv(sock, buf, sizeof(buf), 0)) > 0)
    {
        for (nh = (struct nlmsghdr*)buf; NLMSG_OK(nh, len);
             nh = NLMSG_NEXT(nh, len))
        {
            if (nh->nlmsg_type == NLMSG_DONE)
                goto done;
            if (nh->nlmsg_type == NLMSG_ERROR)
            {
                mctpPrErr("Netlink error in route dump");
                close(sock);
                return -1;
            }

            struct rtmsg* rt = (struct rtmsg*)NLMSG_DATA(nh);
            int attrlen = RTM_PAYLOAD(nh);
            struct rtattr* attr;

            /// Walk through attributes
            for (attr = RTM_RTA(rt); RTA_OK(attr, attrlen);
                 attr = RTA_NEXT(attr, attrlen))
            {
                if (attr->rta_type == RTA_DST)
                {
                    /// Assume our destination is a single byte (the EID)
                    uint8_t dst_eid;
                    memcpy(&dst_eid, RTA_DATA(attr), sizeof(dst_eid));
                    if (dst_eid == routeEid)
                    {
                        close(sock);
                        return 1; /// route exists
                    }
                }
            }
        }
    }

done:
    close(sock);
    return 0; /// route not found
}

/**
 * @brief Check whether a neighbor entry for the given routeEid exists
 * @param routeEid EID to check for neighbor existence
 * @return 1 if neighbor exists, 0 if not found, -1 on error
 */
int mctpNeighExists(uint8_t routeEid)
{
    int sock;
    struct sockaddr_nl sa;
    char buf[BUF_SIZE];
    struct nlmsghdr* nh;
    int len, ret;

    /// Create netlink socket.
    sock = socket(AF_NETLINK, SOCK_RAW, NETLINK_ROUTE);
    if (sock < 0)
    {
        mctpPrErr("socket");
        return -1;
    }

    memset(&sa, 0, sizeof(sa));
    sa.nl_family = AF_NETLINK;
    sa.nl_pid = 0;

    if (bind(sock, (struct sockaddr*)&sa, sizeof(sa)) < 0)
    {
        mctpPrErr("bind");
        close(sock);
        return -1;
    }

    /// Prepare a dump request for neighbors.
    struct
    {
        struct nlmsghdr nh;
        struct ndmsg nd;
    } req;
    memset(&req, 0, sizeof(req));
    req.nh.nlmsg_len = NLMSG_LENGTH(sizeof(struct ndmsg));
    req.nh.nlmsg_type = RTM_GETNEIGH;
    req.nh.nlmsg_flags = NLM_F_REQUEST | NLM_F_DUMP;
    req.nh.nlmsg_seq = 2;
    req.nh.nlmsg_pid = getpid();
    req.nd.ndm_family = AF_MCTP;

    ret = send(sock, &req, req.nh.nlmsg_len, 0);
    if (ret < 0)
    {
        mctpPrErr("send");
        close(sock);
        return -1;
    }
    if (ret != (int)req.nh.nlmsg_len)
    {
        mctpPrErr(" %s: sendto: short (send %d, expected %d )", __func__, ret,
                  req.nh.nlmsg_len);
        close(sock);
        return -1;
    }

    /// Loop to read all neighbor entries.
    while ((len = recv(sock, buf, sizeof(buf), 0)) > 0)
    {
        for (nh = (struct nlmsghdr*)buf; NLMSG_OK(nh, len);
             nh = NLMSG_NEXT(nh, len))
        {
            if (nh->nlmsg_type == NLMSG_DONE)
                goto done;
            if (nh->nlmsg_type == NLMSG_ERROR)
            {
                mctpPrErr("Netlink error in neigh dump");
                close(sock);
                return -1;
            }

            struct ndmsg* nd = (struct ndmsg*)NLMSG_DATA(nh);
            int attrlen = NLMSG_PAYLOAD(nh, sizeof(struct ndmsg));
            struct rtattr* attr =
                (struct rtattr*)((char*)nd + NLMSG_ALIGN(sizeof(struct ndmsg)));
            for (; RTA_OK(attr, attrlen); attr = RTA_NEXT(attr, attrlen))
            {
                if (attr->rta_type == NDA_DST)
                {
                    /// Assume the destination is a single byte (the EID)
                    uint8_t dst_eid;
                    memcpy(&dst_eid, RTA_DATA(attr), sizeof(dst_eid));
                    if (dst_eid == routeEid)
                    {
                        close(sock);
                        return 1; /// neighbor exists
                    }
                }
            }
        }
    }
done:
    close(sock);
    return 0; /// neighbor not found
}

/**
 * @brief Set link using Netlink
 * @param index Interface index to set up
 * @return 0 on success, -1 on error
 */
int mctpLinkSet(int index)
{
    int sock, ret;
    struct sockaddr_nl addr;
    struct
    {
        struct nlmsghdr nh;
        struct ifinfomsg ifmsg;
        uint8_t rta_buff[256];
    } req;

    memset(&req, 0, sizeof(req)); /// Zero out all fields

    sock = socket(AF_NETLINK, SOCK_RAW, NETLINK_ROUTE);
    if (sock < 0)
    {
        mctpPrErr("socket");
        return -1;
    }
    memset(&addr, 0, sizeof(addr));
    addr.nl_family = AF_NETLINK;
    addr.nl_pid = 0;

    req.ifmsg.ifi_index = index;
    req.ifmsg.ifi_family = AF_MCTP;

    req.nh.nlmsg_type = RTM_NEWLINK;
    req.nh.nlmsg_flags = NLM_F_REQUEST | NLM_F_ACK;

    req.nh.nlmsg_len = NLMSG_LENGTH(sizeof(req.ifmsg));

    req.ifmsg.ifi_flags |= INTF_UP;
    req.ifmsg.ifi_change |= INTF_UP;

    ret = sendto(sock, &req, req.nh.nlmsg_len, 0, (struct sockaddr*)&addr,
                 sizeof(addr));
    if (ret < 0)
    {
        mctpPrErr("send RTM_NEWADDR");
        close(sock);
        return -1;
    }

    if (ret != (int)req.nh.nlmsg_len)
    {
        mctpPrErr("%s: sendto: short (send %d, expected %d )", __func__, ret,
                  req.nh.nlmsg_len);
        close(sock);
        return -1;
    }
    close(sock);
    return 0;
}

/**
 * @brief Set link and net using Netlink
 * @param index Interface index to configure
 * @param net Network ID to set
 * @return 0 on success, -1 on error
 */
int mctpLinkSetNet(int index, uint32_t net)
{
    int sock, ret;
    struct sockaddr_nl addr;
    struct
    {
        struct nlmsghdr nh;
        struct ifinfomsg ifmsg;
        uint8_t rta_buff[256];
    } req;

    memset(&req, 0, sizeof(req)); /// Zero out all fields

    sock = socket(AF_NETLINK, SOCK_RAW, NETLINK_ROUTE);
    if (sock < 0)
    {
        mctpPrErr("socket");
        return -1;
    }
    memset(&addr, 0, sizeof(addr));
    addr.nl_family = AF_NETLINK;
    addr.nl_pid = 0;

    req.ifmsg.ifi_index = index;
    req.ifmsg.ifi_family = AF_MCTP;

    req.nh.nlmsg_type = RTM_NEWLINK;
    req.nh.nlmsg_flags = NLM_F_REQUEST | NLM_F_ACK;

    req.nh.nlmsg_len = NLMSG_LENGTH(sizeof(req.ifmsg));

    req.ifmsg.ifi_flags |= INTF_UP;
    req.ifmsg.ifi_change |= INTF_UP;

    /**
     * Nested
     * IFLA_AF_SPEC
     *     AF_MCTP
     *         IFLA_MCTP_NET
     *         ... future device properties
     */
    struct rtattr *rta1, *rta2;
    size_t rta_len1, rta_len2, space1, space2;
    uint8_t buff1[100], buff2[100];

    struct rtattr* rta;
    size_t rta_len;

    rta_len = sizeof(req.rta_buff);
    rta = (struct rtattr*)req.rta_buff;

    rta2 = (struct rtattr*)buff2;
    rta_len2 = sizeof(buff2);
    space2 = 0;
    space2 +=
        mctpPutRtnlmsgAttr(&rta2, &rta_len2, IFLA_MCTP_NET, &net, sizeof(net));
    rta1 = (struct rtattr*)buff1;
    rta_len1 = sizeof(buff1);
    space1 = mctpPutRtnlmsgAttr(&rta1, &rta_len1, AF_MCTP | NLA_F_NESTED, buff2,
                                space2);
    req.nh.nlmsg_len += mctpPutRtnlmsgAttr(
        &rta, &rta_len, IFLA_AF_SPEC | NLA_F_NESTED, buff1, space1);

    ret = sendto(sock, &req, req.nh.nlmsg_len, 0, (struct sockaddr*)&addr,
                 sizeof(addr));
    if (ret < 0)
    {
        mctpPrErr("send RTM_NEWADDR");
        close(sock);
        return -1;
    }

    if (ret != (int)req.nh.nlmsg_len)
    {
        mctpPrErr("%s: sendto: short (send %d, expected %d )", __func__, ret,
                  req.nh.nlmsg_len);
        close(sock);
        return -1;
    }
    close(sock);
    return 0;
}

/**
 * @brief Add a addr using Netlink
 * @param eid EID to delete
 * @param index Interface index
 * @return 0 on success, -1 on error
 */
int mctpAddrDel(uint8_t eid, int index)
{
    int sock;
    struct sockaddr_nl addr;

    struct
    {
        struct nlmsghdr nh;
        struct ifaddrmsg ifmsg;
        struct rtattr rta;
        uint8_t data[4];
    } req;

    memset(&req, 0, sizeof(req)); /// Zero out all fields

    int ret;

    /// Check if the address exists.
    ret = mctpAddrExists(eid);
    if (ret < 0)
    {
        mctpPrErr("Error checking if address exists");
        /// return ret;
    }

    /// If the address does not exist, there is nothing to delete.
    if (ret == 0)
    {
        mctpPrErr("addr not present, no need to delete");
        /// Address does not exist, so nothing to delete
        return 0;
    }

    sock = socket(AF_NETLINK, SOCK_RAW, NETLINK_ROUTE);
    if (sock < 0)
    {
        mctpPrErr("socket");
        return -1;
    }
    memset(&addr, 0, sizeof(addr));
    addr.nl_family = AF_NETLINK;
    addr.nl_pid = 0;

    memset(&req, 0, sizeof(req));

    req.ifmsg.ifa_index = index;
    req.ifmsg.ifa_family = AF_MCTP;

    /// req.nh.nlmsg_len = NLMSG_LENGTH(sizeof(struct ifaddrmsg));
    req.nh.nlmsg_type = RTM_DELADDR;
    req.nh.nlmsg_flags = NLM_F_REQUEST | NLM_F_ACK;

    req.ifmsg.ifa_family = AF_MCTP;

    req.rta.rta_type = IFA_LOCAL;
    req.rta.rta_len = RTA_LENGTH(sizeof(eid));
    memcpy(RTA_DATA(&req.rta), &eid, sizeof(eid));

    req.nh.nlmsg_len = NLMSG_LENGTH(sizeof(req.ifmsg)) + RTA_SPACE(sizeof(eid));

    ret = sendto(sock, &req, req.nh.nlmsg_len, 0, (struct sockaddr*)&addr,
                 sizeof(addr));
    if (ret < 0)
    {
        mctpPrErr("send RTM_DELADDR");
        close(sock);
        return -1;
    }
    if (ret != (int)req.nh.nlmsg_len)
    {
        mctpPrErr("%s: sendto: short (send %d, expected %d )", __func__, ret,
                  req.nh.nlmsg_len);
        close(sock);
        return -1;
    }

    close(sock);
    return 0;
}

/**
 * @brief Add a addr using Netlink
 * @param eid EID to add
 * @param index Interface index
 * @return 0 on success, -1 on error
 */
int mctpAddrAdd(uint8_t eid, int index)
{
    int sock, ret;
    struct sockaddr_nl addr;

    struct
    {
        struct nlmsghdr nh;
        struct ifaddrmsg ifmsg;
        struct rtattr rta;
        uint8_t data[4];
    } req;

    memset(&req, 0, sizeof(req)); /// Zero out all fields
    sock = socket(AF_NETLINK, SOCK_RAW, NETLINK_ROUTE);
    if (sock < 0)
    {
        mctpPrErr("socket");
        return -1;
    }
    memset(&addr, 0, sizeof(addr));
    addr.nl_family = AF_NETLINK;
    addr.nl_pid = 0;

    req.nh.nlmsg_type = RTM_NEWADDR;
    req.nh.nlmsg_flags = NLM_F_REQUEST | NLM_F_ACK;

    req.ifmsg.ifa_index = index;
    req.ifmsg.ifa_family = AF_MCTP;

    req.rta.rta_type = IFA_LOCAL;
    req.rta.rta_len = RTA_LENGTH(sizeof(eid));
    memcpy(RTA_DATA(&req.rta), &eid, sizeof(eid));

    req.nh.nlmsg_len = NLMSG_LENGTH(sizeof(req.ifmsg)) + RTA_SPACE(sizeof(eid));

    ret = sendto(sock, &req, req.nh.nlmsg_len, 0, (struct sockaddr*)&addr,
                 sizeof(addr));
    if (ret < 0)
    {
        mctpPrErr("send RTM_NEWADDR");
        close(sock);
        return -1;
    }

    if (ret != (int)req.nh.nlmsg_len)
    {
        mctpPrErr("%s: sendto: short (send %d, expected %d )", __func__, ret,
                  req.nh.nlmsg_len);
        close(sock);
        return -1;
    }
    close(sock);
    return 0;
}

/**
 * @brief Add a route using Netlink
 * @param routeEid EID to add route for
 * @param index Interface index
 * @return 0 on success, -1 on error
 */
int mctpRouteAdd(uint8_t routeEid, int index)
{
    int sock;
    struct sockaddr_nl addr;
    struct
    {
        struct nlmsghdr nh;
        struct rtmsg rt;
        char attrbuf[256];
    } req;
    int ret;
    struct rtattr* rta;

    sock = socket(AF_NETLINK, SOCK_RAW, NETLINK_ROUTE);
    if (sock < 0)
    {
        mctpPrErr("socket");
        return -1;
    }
    memset(&addr, 0, sizeof(addr));
    addr.nl_family = AF_NETLINK;
    addr.nl_pid = 0;

    memset(&req, 0, sizeof(req));
    req.nh.nlmsg_len = NLMSG_LENGTH(sizeof(struct rtmsg));
    req.nh.nlmsg_type = RTM_NEWROUTE;
    req.nh.nlmsg_flags = NLM_F_REQUEST | NLM_F_ACK;
    req.rt.rtm_family = AF_MCTP;
    req.rt.rtm_type = RTN_UNICAST;
    req.rt.rtm_dst_len = 0;

    /// Set first attribute: Destination (RTA_DST)
    rta = (struct rtattr*)req.attrbuf;
    rta->rta_type = RTA_DST;
    rta->rta_len = RTA_LENGTH(sizeof(uint8_t));
    memcpy(RTA_DATA(rta), &routeEid, sizeof(uint8_t));
    req.nh.nlmsg_len += RTA_ALIGN(rta->rta_len); /// Ensure alignment

    /// Set second attribute: Output Interface (RTA_OIF)
    rta = (struct rtattr*)((char*)req.attrbuf + RTA_ALIGN(rta->rta_len));
    rta->rta_type = RTA_OIF;
    rta->rta_len = RTA_LENGTH(sizeof(int));
    memcpy(RTA_DATA(rta), &index, sizeof(int));
    req.nh.nlmsg_len += RTA_ALIGN(rta->rta_len); /// Ensure alignment

    ret = sendto(sock, &req, req.nh.nlmsg_len, 0, (struct sockaddr*)&addr,
                 sizeof(addr));
    if (ret < 0)
    {
        mctpPrErr("send RTM_NEWROUTE");
        close(sock);
        return -1;
    }
    if (ret != (int)req.nh.nlmsg_len)
    {
        mctpPrErr(" %s: sendto: short (send %d, expected %d )", __func__, ret,
                  req.nh.nlmsg_len);
        close(sock);
        return -1;
    }

    close(sock);
    return 0;
}

/**
 * @brief Delete a route using Netlink
 * @param routeEid EID to delete route for
 * @param index Interface index
 * @return 0 on success, -1 on error
 */
int mctpRouteDel(uint8_t routeEid, int index)
{
    int sock;
    struct sockaddr_nl addr;
    struct
    {
        struct nlmsghdr nh;
        struct rtmsg rt;
        char attrbuf[256];
    } req;
    int ret;
    struct rtattr* rta;

    sock = socket(AF_NETLINK, SOCK_RAW, NETLINK_ROUTE);
    if (sock < 0)
    {
        mctpPrErr("socket");
        return -1;
    }
    memset(&addr, 0, sizeof(addr));
    addr.nl_family = AF_NETLINK;
    addr.nl_pid = 0;

    memset(&req, 0, sizeof(req));
    req.nh.nlmsg_len = NLMSG_LENGTH(sizeof(struct rtmsg));
    req.nh.nlmsg_type = RTM_DELROUTE;
    req.nh.nlmsg_flags = NLM_F_REQUEST | NLM_F_ACK;
    req.rt.rtm_family = AF_MCTP;
    req.rt.rtm_type = RTN_UNICAST;
    req.rt.rtm_dst_len = 0;

    /// Set first attribute: Destination (RTA_DST)
    rta = (struct rtattr*)req.attrbuf;
    rta->rta_type = RTA_DST;
    rta->rta_len = RTA_LENGTH(sizeof(uint8_t));
    memcpy(RTA_DATA(rta), &routeEid, sizeof(uint8_t));
    req.nh.nlmsg_len += RTA_ALIGN(rta->rta_len); /// Ensure alignment

    /// Set second attribute: Output Interface (RTA_OIF)
    rta = (struct rtattr*)((char*)req.attrbuf + RTA_ALIGN(rta->rta_len));
    rta->rta_type = RTA_OIF;
    rta->rta_len = RTA_LENGTH(sizeof(int));
    memcpy(RTA_DATA(rta), &index, sizeof(int));
    req.nh.nlmsg_len += RTA_ALIGN(rta->rta_len); /// Ensure alignment

    ret = sendto(sock, &req, req.nh.nlmsg_len, 0, (struct sockaddr*)&addr,
                 sizeof(addr));
    if (ret < 0)
    {
        mctpPrErr("send RTM_NEWROUTE");
        close(sock);
        return -1;
    }
    close(sock);
    return 0;
}

/**
 * @brief Add a neighbor entry using Netlink
 * @param routeEid EID to add neighbor for
 * @param lladdr Link layer address (hardware address)
 * @param index Interface index
 * @return 0 on success, -1 on error
 */
int mctpNeighAdd(uint8_t routeEid, const char* lladdr, int index)
{
    int sock, ret;
    struct sockaddr_nl addr;
    struct
    {
        struct nlmsghdr nh;
        struct ndmsg nd;
        char attrbuf[256];
    } req;

    struct rtattr* rta;

    sock = socket(AF_NETLINK, SOCK_RAW, NETLINK_ROUTE);
    if (sock < 0)
    {
        mctpPrErr("socket");
        return -1;
    }
    memset(&addr, 0, sizeof(addr));
    addr.nl_family = AF_NETLINK;
    addr.nl_pid = 0;

    memset(&req, 0, sizeof(req));
    req.nh.nlmsg_len = NLMSG_LENGTH(sizeof(struct ndmsg));
    req.nh.nlmsg_type = RTM_NEWNEIGH;
    req.nh.nlmsg_flags = NLM_F_REQUEST | NLM_F_ACK;

    req.nd.ndm_ifindex = index;
    req.nd.ndm_family = AF_MCTP;
    /// Set neighbor state to reachable (NTF_ROUTER, NUD_REACHABLE, etc. as
    /// appropriate)
    req.nd.ndm_state = NUD_REACHABLE;
    /// Optionally, set the flags (if required)

    /// Add destination attribute (NDA_DST) – destination is one byte (the EID)
    rta = (struct rtattr*)req.attrbuf;
    rta->rta_type = NDA_DST;
    rta->rta_len = RTA_LENGTH(sizeof(uint8_t));
    memcpy(RTA_DATA(rta), &routeEid, sizeof(uint8_t));
    req.nh.nlmsg_len += RTA_ALIGN(rta->rta_len); /// Ensure alignment

    /// Add link-layer address attribute (NDA_LLADDR)
    rta = (struct rtattr*)(((char*)req.attrbuf) + RTA_ALIGN(rta->rta_len));

    rta->rta_type = NDA_LLADDR;
    rta->rta_len = RTA_LENGTH(PID_SIZE);
    memcpy(RTA_DATA(rta), lladdr, PID_SIZE);
    req.nh.nlmsg_len += RTA_ALIGN(rta->rta_len);

    ret = sendto(sock, &req, req.nh.nlmsg_len, 0, (struct sockaddr*)&addr,
                 sizeof(addr));
    if (ret < 0)
    {
        mctpPrErr("send RTM_NEWNEIGH");
        close(sock);
        return -1;
    }
    if (ret != (int)req.nh.nlmsg_len)
    {
        mctpPrErr("%s: sendto: short (send %d, expected %d )", __func__, ret,
                  req.nh.nlmsg_len);
        close(sock);
        return -1;
    }

    close(sock);
    return 0;
}

/**
 * @brief Delete a neighbor entry using Netlink
 * @param routeEid EID to delete neighbor for
 * @param lladdr Link layer address (hardware address)
 * @param index Interface index
 * @return 0 on success, -1 on error
 */
int mctpNeighDel(uint8_t routeEid, const char* lladdr, int index)
{
    int sock, ret;
    struct sockaddr_nl addr;
    struct
    {
        struct nlmsghdr nh;
        struct ndmsg nd;
        char attrbuf[256];
    } req;

    struct rtattr* rta;

    sock = socket(AF_NETLINK, SOCK_RAW, NETLINK_ROUTE);
    if (sock < 0)
    {
        mctpPrErr("socket");
        return -1;
    }

    memset(&addr, 0, sizeof(addr));
    addr.nl_family = AF_NETLINK;
    addr.nl_pid = 0;

    memset(&req, 0, sizeof(req));
    req.nh.nlmsg_len = NLMSG_LENGTH(sizeof(struct ndmsg));
    req.nh.nlmsg_type = RTM_DELNEIGH;
    req.nh.nlmsg_flags = NLM_F_REQUEST | NLM_F_ACK;

    req.nd.ndm_ifindex = index;
    req.nd.ndm_family = AF_MCTP;

    /// Add destination attribute (NDA_DST) – destination is one byte (the EID)
    rta = (struct rtattr*)req.attrbuf;
    rta->rta_type = NDA_DST;
    rta->rta_len = RTA_LENGTH(sizeof(uint8_t));
    memcpy(RTA_DATA(rta), &routeEid, sizeof(uint8_t));
    req.nh.nlmsg_len += RTA_ALIGN(rta->rta_len); /// Ensure alignment

    /// Add link-layer address attribute (NDA_LLADDR)
    rta = (struct rtattr*)(((char*)req.attrbuf) + RTA_ALIGN(rta->rta_len));

    rta->rta_type = NDA_LLADDR;
    rta->rta_len = RTA_LENGTH(PID_SIZE);
    memcpy(RTA_DATA(rta), lladdr, PID_SIZE);
    req.nh.nlmsg_len += RTA_ALIGN(rta->rta_len);

    ret = sendto(sock, &req, req.nh.nlmsg_len, 0, (struct sockaddr*)&addr,
                 sizeof(addr));
    if (ret < 0)
    {
        mctpPrErr("send RTM_DELNEIGH");
        close(sock);
        return -1;
    }
    if (ret != (int)req.nh.nlmsg_len)
    {
        mctpPrErr("%s: sendto: short (send %d, expected %d )", __func__, ret,
                  req.nh.nlmsg_len);
        close(sock);
        return -1;
    }

    close(sock);
    return 0;
}

/**
 * @brief High-level function to add a route and neighbor for a given routeEid
 * @param routeEid EID for which the route and neighbor are to be added
 * @param lladdrStr Link-layer address string (hardware address)
 * @param index Network interface index
 * @return 0 on success, negative value on failure
 */
int addMctpRouteAndNeigh(uint8_t routeEid, const char* lladdrStr, int index)
{
    mctpPrInfo("Adding Route and Neigh for EID 0x%02X ", routeEid);
    int ret;

    /// Check and add route if not already present.
    ret = mctpRouteExists(routeEid);
    if (ret < 0)
    {
        mctpPrErr("Error checking if route exists");
        return ret;
    }

    if (ret != 1)
    {
        ret = mctpRouteAdd(routeEid, index);
        if (ret < 0)
        {
            mctpPrErr("Failed to add route for EID 0x%x", routeEid);
            return ret;
        }
    }

    /// Check and add neighbor if not already present.
    ret = mctpNeighExists(routeEid);
    if (ret < 0)
    {
        mctpPrErr("Error checking if neighbor exists");
        return ret;
    }

    if (ret != 1)
    {
        ret = mctpNeighAdd(routeEid, lladdrStr, index);
        if (ret < 0)
        {
            mctpPrErr("Failed to add neighbor for EID 0x%x", routeEid);
            return ret;
        }
    }
    return 0;
}
