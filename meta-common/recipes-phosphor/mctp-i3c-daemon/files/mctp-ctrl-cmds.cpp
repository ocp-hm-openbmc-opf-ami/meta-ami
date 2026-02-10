#include "mctp-ctrl-cmds.hpp"

#include "MctpDevice.hpp"
#include "utils.hpp"

/** @brief Global pointer for Routing table and its length */
extern mctp_routing_table_t* g_routing_table_entries;
extern int g_routing_table_length;

/** @brief Global pointer for UUID and its length */
extern mctpUuidTable_t* g_uuid_entries;
extern int g_uuid_table_len;

extern mctpMsgTypeTable_t* g_msg_type_entries;
extern int g_msg_type_table_len;

/** @brief Global pointer for VDM and its length */
extern mctpVdmTable_t* g_vdm_entries;
extern int g_vdm_table_len;

/// @brief MCTP mode
extern int mode;
extern int MCTP_I3C_NET;

/// @brief Boost asio connection
extern sdbusplus::asio::connection conn;
extern std::unique_ptr<sdbusplus::asio::object_server> server;

std::unordered_map<
    uint8_t, std::vector<std::shared_ptr<sdbusplus::asio::dbus_interface>>>
    eidInterfaceMap;

int routingId = 0;

/** @brief A hash table that maps endpoint identifiers to their corresponding
 * route eid values */
std::unordered_map<uint8_t, uint8_t> registeredEndpoints;

/**
 * @brief Extracts the endpoint type from the given EID type.
 *
 * This function takes an 8-bit value representing the EID type and extracts
 * the endpoint type by applying a bitmask and shifting the result.
 *
 * @param eidType The 8-bit value representing the EID type.
 * @return The extracted endpoint type as an 8-bit value.
 */
inline uint8_t extractEndpointType(uint8_t eidType)
{
    return (eidType & MCTP_GETEID_ENDPOINT_TYPE_MASK) >> 4;
}

/**
 * @brief Delete route and neighbor for a given EID
 * @param routeVia The EID of the device to route via
 * @param eid The endpoint ID to delete
 */
void deleteRouteAndNeighbor(uint8_t routeVia, uint8_t eid)
{
    DeviceRegistry deviceRegistry;
    MctpDevice* dev = deviceRegistry.findByEid(routeVia);

    mctpPrDebug("%s: Deleting Route and neighbor for start eid: %d", __func__,
                eid);
    mctpNeighDel(eid, (const char*)dev->hwAddr, dev->ifIndex);
    mctpRouteDel(eid, dev->ifIndex);
}

/**
 * @brief Check if an endpoint is registered
 * @param eid The endpoint ID to check
 * @return true if endpoint is registered, false otherwise
 */
bool isEndpointRegistered(mctp_eid_t eid)
{
    return registeredEndpoints.find(eid) != registeredEndpoints.end();
}

/**
 * @brief Check if routing table contains a specific EID
 * @param eid The endpoint ID to check
 * @return true if routing table contains the EID, false otherwise
 */
bool routingTableContainsEid(uint8_t eid)
{
    mctp_routing_table_t* tempEntry = g_routing_table_entries;

    while (tempEntry)
    {
        if (tempEntry->routingTable.startingEid == eid)
        {
            return true;
        }
        tempEntry = tempEntry->next;
    }

    return false;
}

/**
 * @brief Check if an EID is a local EID
 * @param eid The endpoint ID to check
 * @return true if EID is local, false otherwise
 */
bool isLocalEid(uint8_t eid)
{
    for (auto& device : DeviceRegistry::devices)
    {
        if (device.localEid == eid)
            return true;
    }
    return false;
}

/**
 * @brief Check if an EID is a local EID, excluding a specific EID
 * @param eid The endpoint ID to check
 * @param exclude_eid The EID to exclude from the check
 * @return true if EID is local (excluding specified EID), false otherwise
 */
bool isLocalEidExclude(uint8_t eid, uint8_t exclude_eid)
{
    for (auto& device : DeviceRegistry::devices)
    {
        if (device.eid == exclude_eid)
            continue;

        if (device.localEid == eid)
            return true;
    }
    return false;
}

/**
 * @brief Send and receive MCTP control command
 * @param txBuf Pointer to transmit buffer
 * @param txLen Length of transmit buffer
 * @param rxBuf Pointer to receive buffer
 * @param rxLen Pointer to receive buffer length (input/output)
 * @param destEid Destination endpoint ID
 * @param timeoutMs Timeout in milliseconds
 * @return 0 on success, -1 on failure
 */
int mctpCtrlSendRecv(void* txBuf, size_t txLen, uint8_t* rxBuf, size_t* rxLen,
                     uint8_t destEid, int timeoutMs)
{
    int sd, rc;
    socklen_t addrLen;
    ssize_t peekLen;
    struct sockaddr_mctp addr;
    bool debugEnabled = false;

    memset(&addr, 0, sizeof(addr));
    addrLen = sizeof(addr);

    uint8_t logEid = getDebugEid();

    /// mctp packet trace if debugEid is not set or matches destEid
    if (!isEidValid(logEid) || (isEidValid(logEid) && (destEid == logEid)))
    {
        debugEnabled = true;
    }

    // Get global socket - error if not available
    sd = DeviceRegistry::getGlobalSocket();
    if (sd < 0)
    {
        mctpPrErr("%s: Global socket not available", __func__);
        return -1;
    }

    /// Setup destination
    addr.smctp_family = AF_MCTP;
    addr.smctp_network = MCTP_I3C_NET;
    addr.smctp_type = MCTP_TYPE_CONTROL;
    addr.smctp_tag = MCTP_TAG_OWNER;
    addr.smctp_addr.s_addr = destEid;

    /// Send
    rc = sendto(sd, txBuf, txLen, 0, (struct sockaddr*)&addr, addrLen);
    if (rc != (int)txLen)
    {
        mctpPrErr("%s: sendto failed", __func__);
        return -1;
    }

    if (debugEnabled)
        mctpTraceTx(txBuf, txLen);

    /// Wait
    rc = pollWithTimeout(sd, timeoutMs);
    if (rc < 0)
    {
        mctpPrErr("%s: poll timeout/error", __func__);
        return -1;
    }

    /// Peek response size
    peekLen = recvfrom(sd, NULL, 0, MSG_PEEK | MSG_TRUNC, NULL, 0);
    if (peekLen < 0)
    {
        mctpPrErr("%s: recvfrom peek failed", __func__);
        return -1;
    }
    if ((size_t)peekLen > *rxLen)
    {
        mctpPrErr("%s: response too large (%zd > %zu)", __func__, peekLen,
                  *rxLen);
        return -1;
    }

    /// Receive
    rc = recvfrom(sd, rxBuf, peekLen, MSG_TRUNC, NULL, 0);
    if (rc < 0)
    {
        mctpPrErr("%s: recvfrom failed", __func__);
        return -1;
    }
    *rxLen = rc;

    if (debugEnabled)
        mctpTraceRx(rxBuf, rc);

    // Global socket stays open - don't close it
    return 0;
}

/**
 * @brief Send and receive MCTP control command using extended addressing
 * @param txBuf Pointer to transmit buffer
 * @param txLen Length of transmit buffer
 * @param rxBuf Pointer to receive buffer
 * @param rxLen Pointer to receive buffer length (input/output)
 * @param lladdr Pointer to link-layer address
 * @param lladdrLen Length of link-layer address
 * @param ifIndex Network interface index
 * @param timeoutMs Timeout in milliseconds
 * @param eid Pointer to store received EID (optional)
 * @return 0 on success, negative value on failure
 */
int mctpCtrlSendRecvExtended(void* txBuf, size_t txLen, uint8_t* rxBuf,
                             size_t* rxLen, const uint8_t* lladdr,
                             size_t lladdrLen, int ifIndex, int timeoutMs,
                             uint8_t* eid = nullptr)
{
    int sd, rc;
    socklen_t addrLen;
    ssize_t peekLen;
    struct sockaddr_mctp_ext addr;

    memset(&addr, 0, sizeof(addr));

    // Get global socket - error if not available
    sd = DeviceRegistry::getGlobalSocket();
    if (sd < 0)
    {
        mctpPrErr("%s: Global socket not available", __func__);
        return -1;
    }

    /// Base fields
    addr.smctp_base.smctp_family = AF_MCTP;
    addr.smctp_base.smctp_network = MCTP_I3C_NET;
    addr.smctp_base.smctp_type = MCTP_TYPE_CONTROL;
    addr.smctp_base.smctp_tag = MCTP_TAG_OWNER;

    addrLen = sizeof(struct sockaddr_mctp_ext);
    addr.smctp_ifindex = ifIndex;
    addr.smctp_halen = lladdrLen;
    memcpy(addr.smctp_haddr, lladdr, lladdrLen);

    /// Send
    rc = sendto(sd, txBuf, txLen, 0, (struct sockaddr*)&addr, addrLen);
    if (rc != (int)txLen)
    {
        mctpPrErr("%s: sendto failed", __func__);
        return -1;
    }
    mctpTraceTx(txBuf, txLen);

    /// Poll
    rc = pollWithTimeout(sd, timeoutMs);
    if (rc < 0)
    {
        mctpPrErr("%s: poll timeout/error", __func__);
        return -1;
    }

    /// Peek to get response length
    peekLen = recvfrom(sd, NULL, 0, MSG_PEEK | MSG_TRUNC, NULL, 0);
    if (peekLen < 0)
    {
        mctpPrErr("%s: recvfrom peek failed", __func__);
        return -1;
    }

    if ((size_t)peekLen > *rxLen)
    {
        mctpPrErr("%s: response too large (%zd > %zu)", __func__, peekLen,
                  *rxLen);
        return -1;
    }

    /// Actual receive
    rc = recvfrom(sd, rxBuf, peekLen, MSG_TRUNC, (struct sockaddr*)&addr,
                  &addrLen);
    if (rc < 0)
    {
        mctpPrErr("%s: recvfrom failed", __func__);
        return -1;
    }

    *rxLen = rc;
    mctpTraceRx(rxBuf, rc);

    if (*rxLen >= MIN_RESP_LENGTH)
    {
        uint8_t completionCode = rxBuf[STATUS_INDEX]; // hdr.completionCode
        if (completionCode != MCTP_CTRL_CC_SUCCESS)
        {
            mctpPrErr("%s: command failed, completionCode=0x%02x", __func__,
                      completionCode);
            return -completionCode; // return negative for error
        }
    }
    else
    {
        mctpPrErr("%s: response too short for completion code", __func__);
        return -1;
    }

    if (eid)
    {
        *eid = addr.smctp_base.smctp_addr.s_addr;
    }

    // Global socket stays open - don't close it
    return 0;
}

/**
 * @brief Send discovery notify command to a device
 * @param device Reference to MctpDevice
 * @return 0 on success, negative value on failure
 */
int sendDiscoveryNotify(MctpDevice& device)
{
    mctpPrInfo("Sending Discovery Notify cmd");
    struct mctpCtrlCmdDiscoveryNotify cmd_discovery_notify;
    uint8_t rxBuf[64];
    size_t rxLen = sizeof(rxBuf);

    if (!mctpEncodeCtrlCmdDiscoveryNotify(&cmd_discovery_notify))
    {
        mctpPrErr("%s mctp_encode_ctrl_cmd_discovery_notify failed ", __func__);
        return -1;
    }

    int rc = mctpCtrlSendRecvExtended(
        reinterpret_cast<uint8_t*>(&cmd_discovery_notify),
        sizeof(cmd_discovery_notify), rxBuf, &rxLen, device.hwAddr,
        sizeof(device.hwAddr), device.ifIndex, 5000, &device.eid);

    if (rc < 0)
    {
        mctpPrErr("%s: mctp_send_and_recv_extended failed", __func__);
        return rc;
    }

    int ret = addMctpRouteAndNeigh(device.eid, (const char*)device.hwAddr,
                                   device.ifIndex);
    if (ret < 0)
    {
        mctpPrErr("%s:adding secondary eid route and neigh failed ", __func__);
        return -1;
    }
    return 0;
}

/**
 * @brief Get MCTP version from a device
 * @param device Reference to MctpDevice
 * @return 0 on success, negative value on failure
 */
int getMctpVersion(MctpDevice& device)
{
    mctpPrInfo("Sending Get mctp version cmd");
    struct mctpCtrlCmdGetMctpVerSupport getMctpVersion;
    uint8_t rxBuf[64];
    size_t rxLen = sizeof(rxBuf);

    if (!mctpEncodeCtrlCmdGetVerSupport(&getMctpVersion, MCTP_TYPE_CONTROL))
    {
        mctpPrErr("%s mctp_encode_ctrl_cmd_get_msg_type failed ", __func__);
        return -1;
    }

    return mctpCtrlSendRecvExtended(
        reinterpret_cast<uint8_t*>(&getMctpVersion), sizeof(getMctpVersion),
        rxBuf, &rxLen, device.hwAddr, sizeof(device.hwAddr), device.ifIndex,
        5000);
}

/**
 * @brief Get EID from a device
 * @param device Reference to MctpDevice
 * @return 0 on success, negative value on failure
 */
int getEid(MctpDevice& device)
{
    mctpPrInfo("Sending Get EID cmd");
    uint8_t rxBuf[64];
    size_t rxLen = sizeof(rxBuf);
    mctpCtrlCmdGetEid getEid;
    struct mctpCtrlRespGetEid getEidResp;

    if (!mctpEncodeCtrlCmdGetEid(&getEid))
    {
        mctpPrErr("%s mctp_encode_ctrl_cmd_get_eid failed ", __func__);
        return -1;
    }

    auto rc = mctpCtrlSendRecvExtended(
        reinterpret_cast<uint8_t*>(&getEid), sizeof(getEid), rxBuf, &rxLen,
        device.hwAddr, sizeof(device.hwAddr), device.ifIndex, 5000);

    if (rc < 0)
    {
        mctpPrErr("%s: mctp_send_and_recv_extended failed", __func__);
        return rc;
    }

    if (rxLen == sizeof(struct mctpCtrlRespGetEid))
    {
        getEidResp = *(reinterpret_cast<struct mctpCtrlRespGetEid*>(rxBuf));

        if (extractEndpointType(getEidResp.eidType) ==
            MCTP_GETEID_ENDPOINT_TYPE_BUSOWNER_BRIDGE)
        {
            mctpPrInfo("EID: 0x%02x Endpoint Type: Busowner/bridge",
                       device.eid);
            device.isMctpBridge = true;
        }
    }
    return rc;
}

/**
 * @brief Add route for given EID
 * @param eid Endpoint ID
 * @param lladdr Link-layer address
 * @param ifIndex Network interface index
 * @return 0 on success, negative value on failure
 */
int addRoute(uint8_t eid, const uint8_t* lladdr, int ifIndex)
{
    int ret;

    ret = addMctpRouteAndNeigh(eid, (const char*)lladdr, ifIndex);
    if (ret < 0)
    {
        mctpPrErr("%s: add route failed", __func__);
    }
    return ret;
}

/**
 * @brief Add address for given EID
 * @param eid Endpoint ID
 * @param ifIndex Network interface index
 * @return 0 on success, negative value on failure
 */
int addAddr(uint8_t eid, int ifIndex)
{
    int ret;

    ret = mctpAddrAdd(eid, ifIndex);
    if (ret < 0)
    {
        mctpPrErr("%s: add route failed", __func__);
    }
    return ret;
}

/**
 * @brief Get supported message types from a device
 * @param device Reference to MctpDevice
 * @return 0 on success, negative value on failure
 */
int getMsgType(MctpDevice& device)
{
    mctpPrInfo("Sending Get mctp msg type cmd");
    uint8_t rxBuf[64];
    size_t rxLen = sizeof(rxBuf);

    struct mctpCtrlCmdGetMsgTypeSupport getMsgType;

    if (!mctpEncodeCtrlCmdGetMsgType(&getMsgType))
    {
        mctpPrErr("%s mctp_encode_ctrl_cmd_get_ver_support failed ", __func__);
        return -1;
    }

    return mctpCtrlSendRecv(reinterpret_cast<uint8_t*>(&getMsgType),
                            sizeof(getMsgType), rxBuf, &rxLen, device.eid,
                            5000);
}

/**
 * @brief Get VDM (Vendor Defined Message) support from a device
 * @param device Reference to MctpDevice
 * @return 0 on success, negative value on failure
 */
int getVdmSupport(MctpDevice& device)
{
    mctpPrInfo("Sending Get vdm support cmd");
    uint8_t rxBuf[64];
    size_t rxLen = sizeof(rxBuf);

    struct mctpCtrlCmdGetVdmSupport getVdmSupport;

    if (!mctpEncodeCtrlCmdGetVdmSupport(&getVdmSupport, MCTP_TYPE_CONTROL))
    {
        mctpPrErr("%s mctp_encode_ctrl_cmd_get_vdm_support failed ", __func__);
        return -1;
    }

    return mctpCtrlSendRecv(reinterpret_cast<uint8_t*>(&getVdmSupport),
                            sizeof(getVdmSupport), rxBuf, &rxLen, device.eid,
                            5000);
}

/**
 * @brief Create a new UUID entry and add to global UUID table
 * @param uuid_tbl Pointer to UUID table entry
 * @return 0 on success, -1 on failure
 */
int mctpUuidEntryAdd(mctpUuidTable_t* uuidTbl)
{
    mctpUuidTable_t *newEntry, *tempEntry;

    /// Create a new Message type entry
    newEntry = (mctpUuidTable_t*)malloc(sizeof(mctpUuidTable_t));
    if (newEntry == NULL)
        return -1;

    /// Copy the Message type contents
    memcpy(newEntry, uuidTbl, sizeof(mctpUuidTable_t));

    /// Check if any entry exist
    if (g_uuid_entries == NULL)
    {
        g_uuid_entries = newEntry;
        newEntry->next = NULL;
        return 0;
    }

    /// Traverse the message type table
    tempEntry = g_uuid_entries;
    while (tempEntry->next != NULL)
    {
        if (tempEntry->eid == newEntry->eid)
            return 0;
        tempEntry = tempEntry->next;
    }
    /// Add at the last
    tempEntry->next = newEntry;
    newEntry->next = NULL;

    /// Increment the global counter
    g_uuid_table_len++;

    return 0;
}

/**
 * @brief Remove single entry by UUID key
 * @param eid Endpoint ID to remove
 * @return 0 on success, -1 on failure
 */
int mctpUuidEntryRemove(uint8_t eid)
{
    mctpUuidTable_t *prev = NULL, *curr = NULL;
    for (curr = g_uuid_entries; curr; curr = curr->next)
    {
        if (curr->eid == eid)
        {
            if (prev)
                prev->next = curr->next;
            else
                g_uuid_entries = curr->next;
            free(curr);
            --g_uuid_table_len;
            return 0;
        }
        prev = curr;
    }
    return -1;
}

/**
 * @brief Delete all the UUID information
 */
void mctpUuidDeleteAll(void)
{
    mctpUuidTable_t* delEntry;

    /// Check if entry exist
    while (g_uuid_entries != NULL)
    {
        delEntry = g_uuid_entries;
        g_uuid_entries = delEntry->next;
        free(delEntry);
    }
}

/**
 * @brief Create a new VDM entry and add to global VDM table
 * @param vdm_tbl Pointer to VDM table entry
 * @param new_cmd_type_node Pointer to command type node
 * @return 0 on success, -1 on failure
 */
int mctpVdmEntryAdd(mctpVdmTable_t* vdmTbl,
                    vendorIdSetCmdTypeNode_t* newCmdTypeNode)
{
    mctpVdmTable_t *newEntry = NULL, *tempEntry = g_vdm_entries;
    vendorIdSetCmdTypeNode_t *newCmdTypeEntry = NULL, *tempCmdTypeEntry = NULL;
    bool findEntry = false;

    if (g_vdm_entries == NULL)
    {
        newEntry = (mctpVdmTable_t*)malloc(sizeof(mctpVdmTable_t));
        newCmdTypeEntry =
            (vendorIdSetCmdTypeNode_t*)malloc(sizeof(vendorIdSetCmdTypeNode_t));

        if (newEntry == NULL || newCmdTypeEntry == NULL)
        {
            free(newEntry);
            free(newCmdTypeEntry);
            return -1;
        }

        memcpy(newEntry, vdmTbl, sizeof(mctpVdmTable_t));
        memcpy(newCmdTypeEntry, newCmdTypeNode,
               sizeof(vendorIdSetCmdTypeNode_t));
        newEntry->next = NULL;
        newCmdTypeEntry->next = NULL;
        newEntry->vendorIdSetCmdType = newCmdTypeEntry;

        g_vdm_entries = newEntry;
        g_vdm_table_len++;
        return 0;
    }

    while (tempEntry != NULL)
    {
        if (tempEntry->eid == vdmTbl->eid)
        {
            if (tempEntry->vIdSetSelector != 0xFF)
            {
                findEntry = true;
                break;
            }
            else
            {
                return 0;
            }
        }
        if (tempEntry->next == NULL)
            break;
        tempEntry = tempEntry->next;
    }

    newCmdTypeEntry =
        (vendorIdSetCmdTypeNode_t*)malloc(sizeof(vendorIdSetCmdTypeNode_t));
    if (newCmdTypeEntry == NULL)
    {
        return -1;
    }
    memcpy(newCmdTypeEntry, newCmdTypeNode, sizeof(vendorIdSetCmdTypeNode_t));
    newCmdTypeEntry->next = NULL;

    if (findEntry)
    {
        tempCmdTypeEntry = tempEntry->vendorIdSetCmdType;
        while (tempCmdTypeEntry->next != NULL)
        {
            tempCmdTypeEntry = tempCmdTypeEntry->next;
        }
        tempCmdTypeEntry->next = newCmdTypeEntry;
        tempEntry->vIdSetSelector = vdmTbl->vIdSetSelector;
    }
    else
    {
        newEntry = (mctpVdmTable_t*)malloc(sizeof(mctpVdmTable_t));
        if (newEntry == NULL)
        {
            free(newCmdTypeEntry);
            return -1;
        }
        memcpy(newEntry, vdmTbl, sizeof(mctpVdmTable_t));
        newEntry->vendorIdSetCmdType = newCmdTypeEntry;
        newEntry->next = NULL;

        tempEntry->next = newEntry;
        g_vdm_table_len++;
    }

    return 0;
}

/**
 * @brief Delete all the VDM information
 */
void mctpVdmDeleteAll(void)
{
    mctpVdmTable_t* current = g_vdm_entries;
    mctpVdmTable_t* next;

    while (current != NULL)
    {
        next = current->next;

        vendorIdSetCmdTypeNode_t* cmdCurrent = current->vendorIdSetCmdType;
        while (cmdCurrent != NULL)
        {
            vendorIdSetCmdTypeNode_t* cmdNext = cmdCurrent->next;
            free(cmdCurrent);
            cmdCurrent = cmdNext;
        }

        free(current);
        current = next;
    }

    g_vdm_entries = NULL;
}

/**
 * @brief Validate a routing entry
 * @param routingTableEntry Pointer to routing table entry
 * @param device Reference to MctpDevice
 * @return ROUTE_VALID on success, ROUTE_SKIP otherwise
 */
int validateRoutingEntry(struct getRoutingTableEntry* routingTableEntry,
                         MctpDevice& device)
{
    if (!isEidValid(routingTableEntry->startingEid))
    {
        return ROUTE_SKIP;
    }

    if (isLocalEid(routingTableEntry->startingEid))
    {
        return ROUTE_SKIP;
    }

    if ((routingTableEntry->startingEid == device.eid) &&
        routingTableEntry->physTransportBindingId != I3C_PHY_BINDING)
    {
        return ROUTE_SKIP;
    }

    if (routingTableEntry->eidRangeSize > 1)
    {
        return ROUTE_SKIP;
    }

    if (routingTableEntry->physTransportBindingId != I3C_PHY_BINDING &&
        routingTableEntry->physTransportBindingId != VENDOR_BINDING)
    {
        return ROUTE_SKIP;
    }

    return ROUTE_VALID;
}

/**
 * @brief Create a new routing entry and add to global routing table
 * @param routingTableEntry Pointer to routing table entry
 * @param device Reference to MctpDevice
 * @return 0 on success, negative value on failure
 */
int mctpRoutingEntryAdd(struct getRoutingTableEntry* routingTableEntry,
                        MctpDevice& device)
{
    // mctpPrErr("Adding EID 0x%02X to Routing Table ", device.eid);
    uint8_t routeEid = routingTableEntry->startingEid;
    int rc, ret;

    rc = validateRoutingEntry(routingTableEntry, device);
    if (rc != ROUTE_VALID)
    {
        // mctpPrErr("validate_routing_entry failed for eid 0x%02X",
        // routeEid);
        return rc;
    }
    /// Add route and neighbor via netlink
    ret = addMctpRouteAndNeigh(routeEid, (const char*)&device.hwAddr,
                               device.ifIndex);
    if (ret < 0)
    {
        mctpPrErr("adding mctp route and neigh failed ");
    }

    mctp_routing_table_t *newEntry, *tempEntry;
    /// Create a new Routing table entry
    newEntry = (mctp_routing_table_t*)malloc(sizeof(mctp_routing_table_t));
    if (newEntry == NULL)
        return -1;

    /// Copy the contents
    memcpy(&newEntry->routingTable, routingTableEntry,
           sizeof(struct getRoutingTableEntry));

    newEntry->valid = true;
    newEntry->routeVia = device.eid;

    /// Check if any entry exist
    if (g_routing_table_entries == NULL)
    {
        g_routing_table_entries = newEntry;
        newEntry->next = NULL;

        /// Reset the routing ID to zero
        routingId = 0;

        /// Update the routing ID
        newEntry->id = routingId++;

        g_routing_table_length++;

        if (!isLocalEid(routeEid))
        {
            ret = getVdmTypesForEid(routeEid);
            if (ret == 0)
            {
                getUuidForEid(routeEid);
                getMsgTypesForEid(routeEid);
            }
        }
        return 0;
    }

    /// Traverse the routing table
    tempEntry = g_routing_table_entries;
    while (tempEntry->next != NULL)
    {
        if (tempEntry->routingTable.startingEid ==
            newEntry->routingTable.startingEid)
        {
            mctpPrDebug(
                "%s: Routing table entry with EID: %d already exists, ignoring",
                __func__, tempEntry->routingTable.startingEid);
            tempEntry->valid = true;
            free(newEntry);
            newEntry = NULL;
            return 0;
        }
        tempEntry = tempEntry->next;
    }

    if (tempEntry->routingTable.startingEid ==
        newEntry->routingTable.startingEid)
    {
        mctpPrDebug(
            "%s: Routing table entry with EID: %d already exists, ignoring",
            __func__, tempEntry->routingTable.startingEid);
        tempEntry->valid = true;
        free(newEntry);
        newEntry = NULL;
        return 0;
    }

    /// Add at the last
    tempEntry->next = newEntry;
    newEntry->next = NULL;

    /// Update the routing ID
    newEntry->id = routingId++;

    /// Increment the global counter
    g_routing_table_length++;

    if (!isLocalEid(routeEid))
    {
        ret = getVdmTypesForEid(routeEid);
        if (ret == 0)
        {
            getUuidForEid(routeEid);
            getMsgTypesForEid(routeEid);
        }
    }
    return 0;
}

/**
 * @brief Delete a routing entry by EID
 * @param eid Endpoint ID to delete
 * @return 0 on success, -1 on failure
 */
int mctpRoutingEntryDelete(uint8_t eid)
{
    if ((g_routing_table_entries == NULL) || (!isEidValid(eid)) ||
        (isLocalEid(eid)))
    {
        mctpPrErr(
            "Not valid eid or routing table empty or local eid  or endpoint eid: %d",
            eid);
        return -1;
    }

    mctp_routing_table_t* curr = g_routing_table_entries;
    mctp_routing_table_t* prev = NULL;

    while (curr != NULL)
    {
        if (curr->routingTable.startingEid == eid)
        {
            if (prev == NULL)
            {
                // deleting the head
                g_routing_table_entries = curr->next;
                mctpPrDebug("%s: Routing entry with EID %d deleted (was head)",
                            __func__, eid);
            }
            else
            {
                // Deleting a middle or tail node
                prev->next = curr->next;
                mctpPrDebug("%s: Routing entry with EID %d deleted", __func__,
                            eid);
            }
            free(curr);
            g_routing_table_length--;
            return 0;
        }
        prev = curr;
        curr = curr->next;
    }

    /// Entry not found
    mctpPrDebug("%s: Routing entry with EID %d not found", __func__, eid);
    return -1;
}

/**
 * @brief Delete all the entries in global routing table
 */
void mctpRoutingEntryDeleteAll(void)
{
    mctp_routing_table_t* delEntry = NULL;
    /// Check if entry exist
    while (g_routing_table_entries != NULL)
    {
        delEntry = g_routing_table_entries;
        g_routing_table_entries = delEntry->next;

        mctpPrInfo("Deleting Routing table Entry: 0x%02x", delEntry->id);

        free(delEntry);
    }
    g_routing_table_length = 0;
}

/**
 * @brief Delete all the Message types information
 */
void mctpMsgTypesDeleteAll(void)
{
    mctpMsgTypeTable_t* delEntry;

    /// Check if entry exist
    while (g_msg_type_entries != NULL)
    {
        delEntry = g_msg_type_entries;
        g_msg_type_entries = delEntry->next;
        free(delEntry);
    }
}

/**
 * @brief Remove MCTP type entry by EID
 * @param eid Endpoint ID to remove
 * @return 0 on success, -1 on failure
 */
int mctpMsgTypeEntryRemove(uint8_t eid)
{
    mctpMsgTypeTable_t *prev = NULL, *curr = NULL;
    for (curr = g_msg_type_entries; curr; curr = curr->next)
    {
        if (curr->eid == eid)
        {
            if (prev)
                prev->next = curr->next;
            else
                g_msg_type_entries = curr->next;
            free(curr);
            --g_msg_type_table_len;
            return 0;
        }
        prev = curr;
    }
    return -1;
}

/**
 * @brief Set EID on a device
 * @param device Reference to MctpDevice
 * @param eid The EID to set
 * @return 0 on success, negative value on failure
 */
int setEid(MctpDevice& device, uint8_t eid)
{
    mctpPrInfo("Sending Set Eid cmd");
    uint8_t setOperation = 0;
    uint8_t rxBuf[64];
    size_t rxLen = sizeof(rxBuf);
    mctpCtrlCmdSetEid setEid;
    int rc = 0;

    if (!mctpEncodeCtrlCmdSetEid(&setEid, setOperation, eid))
    {
        mctpPrErr("%s mctp_encode_ctrl_cmd_set_eid failed ", __func__);
        return -1;
    }

    rc = mctpCtrlSendRecvExtended(reinterpret_cast<uint8_t*>(&setEid),
                                  sizeof(setEid), rxBuf, &rxLen, device.hwAddr,
                                  sizeof(device.hwAddr), device.ifIndex, 5000);

    if (rc < 0)
    {
        mctpPrErr("set eid command failed ");
        return -1;
    }

    int ret = addRoute(eid, device.hwAddr, device.ifIndex);
    if (ret < 0)
    {
        mctpPrErr("adding pfr route cmd failed ");
    }

    /// Update device eid
    device.eid = eid;
    return 0;
}

/**
 * @brief Create a new MCTP Message type and add to global message type
 * @param msg_type_tbl Pointer to message type table entry
 * @return 0 on success, -1 on failure
 */
int mctpMsgTypeEntryAdd(mctpMsgTypeTable_t* msgTypeTbl)
{
    mctpMsgTypeTable_t *newEntry, *tempEntry;

    /// Create a new Message type entry
    newEntry = (mctpMsgTypeTable_t*)malloc(sizeof(mctpMsgTypeTable_t));
    if (newEntry == NULL)
        return -1;

    /// Copy the Message type contents
    memcpy(newEntry, msgTypeTbl, sizeof(mctpMsgTypeTable_t));

    /// Check if any entry exist
    if (g_msg_type_entries == NULL)
    {
        g_msg_type_entries = newEntry;
        newEntry->next = NULL;

        return 0;
    }

    /// Traverse the message type table
    tempEntry = g_msg_type_entries;
    while (tempEntry->next != NULL)
    {
        if (tempEntry->eid == newEntry->eid)
        {
            mctpPrDebug(
                "%s: EID %d already exists in message type list, ignoring.",
                __func__, tempEntry->eid);
            return 0;
        }
        tempEntry = tempEntry->next;
    }

    if (tempEntry->eid == newEntry->eid)
    {
        mctpPrDebug("%s: EID %d already exists in message type list, ignoring.",
                    __func__, tempEntry->eid);
        return 0;
    }

    /// Add at the last
    tempEntry->next = newEntry;
    newEntry->next = NULL;

    /// Increment the global counter
    g_msg_type_table_len++;

    return 0;
}

/**
 * @brief Get UUID for given EID
 * @param eid Endpoint ID
 * @return 0 on success, -1 on failure
 */
int getUuidForEid(uint8_t eid)
{
    mctpPrDebug("Get UUID for EID:0x%02X ", eid);

    int rc;
    uint8_t rxBuf[128];
    size_t rxLen = sizeof(rxBuf);

    struct mctpCtrlCmdGetUuid getUuid;

    if (!mctpEncodeCtrlCmdGetUuid(&getUuid))
    {
        mctpPrErr("%s: failed ", __func__);
        return -1;
    }
    memset(rxBuf, 0x0, rxLen);

    rc = mctpCtrlSendRecv(reinterpret_cast<uint8_t*>(&getUuid), sizeof(getUuid),
                          rxBuf, &rxLen, eid, 1000);

    if (rc < 0)
    {
        mctpPrErr("%s cmd failed", __func__);
        return -1;
    }

    // process routing tabel response
    struct mctpCtrlRespGetUuid* resp;

    resp = (struct mctpCtrlRespGetUuid*)rxBuf;

    if (!mctpDecodeRespGetUuid(resp))
    {
        /* Check wheteher device is ready or not */
        if (resp->completionCode == MCTP_CONTROL_MSG_STATUS_ERROR_NOT_READY)
        {
            mctpPrErr("%s: Device is not ready yet..", __func__);
        }
        else
        {
            mctpPrErr("%s: Failed to decode get uuid response", __func__);
        }
        return -1;
    }

    mctpUuidTable_t uuidTable;
    memset(&uuidTable, 0x0, sizeof(mctpUuidTable_t));

    /// Update UUID private params to export to upper layer
    uuidTable.eid = eid;
    memcpy(&uuidTable.uuid, &resp->uuid, 16);
    uuidTable.next = NULL;

    /// Create a new UUID entry and add to list
    int ret = mctpUuidEntryAdd(&uuidTable);
    if (ret < 0)
    {
        mctpPrErr("%s: Failed to update global UUID table..", __func__);
        return -1;
    }
    // mctp_uuid_display();
    return 0;
}

/**
 * @brief Get Message Types for given EID
 * @param eid Endpoint ID
 * @return 0 on success, -1 on failure
 */
int getMsgTypesForEid(uint8_t eid)
{
    mctpPrDebug("Get Mesage Types for EID:0x%02X ", eid);

    int rc;
    uint8_t rxBuf[128];
    size_t rxLen = sizeof(rxBuf);

    struct mctpCtrlCmdGetMsgTypeSupport getMsgTypes;

    if (!mctpEncodeCtrlCmdGetMsgType(&getMsgTypes))
    {
        mctpPrErr("%s: failed ", __func__);
        return -1;
    }
    memset(rxBuf, 0x0, rxLen);

    rc = mctpCtrlSendRecv(reinterpret_cast<uint8_t*>(&getMsgTypes),
                          sizeof(getMsgTypes), rxBuf, &rxLen, eid, 1000);

    if (rc < 0)
    {
        mctpPrErr("%s cmd failed", __func__);
        return -1;
    }

    // process response
    struct mctpCtrlRespGetMsgTypeSupport* resp;

    resp = (struct mctpCtrlRespGetMsgTypeSupport*)rxBuf;

    bool reqRet = mctpDecodeRespGetMsgType(resp);
    if (reqRet == false)
    {
        mctpPrErr("%s: Packet parsing failed", __func__);
        /* Check wheteher device is ready or not */
        if (resp->completionCode == MCTP_CONTROL_MSG_STATUS_ERROR_NOT_READY)
        {
            mctpPrErr("%s: Device is not ready yet..", __func__);
        }
        return -1;
    }

    mctpMsgTypeTable_t msgTypeTable;

    /// Update Message type private params to export to upper layer
    msgTypeTable.next = NULL;
    msgTypeTable.eid = eid;
    msgTypeTable.dataLen =
        ((struct mctpCtrlResp*)resp)->data[MCTP_MSG_TYPE_DATA_LEN_OFFSET];

    if (msgTypeTable.dataLen > (rxLen - 4))
    {
        mctpPrDebug(
            "%s: EID: %d, Data length: %u, but in the response there is only: %zi",
            __func__, eid, msgTypeTable.dataLen, rxLen);
        msgTypeTable.dataLen = rxLen - 4;
    }

    memcpy(&msgTypeTable.data,
           &((struct mctpCtrlResp*)resp)->data[MCTP_MSG_TYPE_DATA_OFFSET],
           msgTypeTable.dataLen);

    /* Create a new Msg type entry and add to list */
    int ret = mctpMsgTypeEntryAdd(&msgTypeTable);
    if (ret < 0)
    {
        mctpPrErr("%s: Failed to update global routing table..", __func__);
        return -1;
    }
    return 0;
}

/**
 * @brief Get VDM Types for given EID
 * @param eid Endpoint ID
 * @return 0 on success, -1 on failure
 */
int getVdmTypesForEid(uint8_t eid)
{
    mctpPrDebug("Get VDM Types for EID:0x%02X ", eid);

    bool hasMoreEntries = true;
    uint8_t rxBuf[128];
    size_t rxLen = sizeof(rxBuf);
    int rc;
    uint8_t vIdSelector = 0;

    while (hasMoreEntries)
    {
        struct mctpCtrlCmdGetVdmSupport getVdmSupport;

        if (!mctpEncodeCtrlCmdGetVdmSupport(&getVdmSupport, vIdSelector))
        {
            mctpPrErr("%s: failed ", __func__);
            return -1;
        }
        memset(rxBuf, 0x0, rxLen);

        rc = mctpCtrlSendRecv(reinterpret_cast<uint8_t*>(&getVdmSupport),
                              sizeof(getVdmSupport), rxBuf, &rxLen, eid, 1000);

        if (rc < 0)
        {
            mctpPrErr("%s getVdmSupport cmd failed", __func__);
            return -1;
        }

        // process response
        struct mctpPciCtrlRespGetVdmSupport vdmResp;
        memset(&vdmResp, 0, sizeof(vdmResp));

        mctpVdmTable_t vdmTable;
        memset(&vdmTable, 0, sizeof(vdmTable));

        vendorIdSetCmdTypeNode_t newCmdTypeNode;
        memset(&newCmdTypeNode, 0, sizeof(newCmdTypeNode));

        struct mctpCtrlResp* respMsg = (struct mctpCtrlResp*)rxBuf;
        int ret;

        if (respMsg->completionCode != MCTP_CTRL_CC_SUCCESS)
        {
            mctpPrErr("%s: Command failed, completionCode=0x%02x", __func__,
                      respMsg->completionCode);
            return -1;
        }

        /* Copy the response message to local structure */
        vdmResp.ctrlHdr = respMsg->hdr;
        vdmResp.completionCode = respMsg->completionCode;
        vdmResp.vendorIdSeSelector = respMsg->data[0];
        vdmResp.vendorIdFormat = respMsg->data[1]; // uint8_t Vendor ID Format
        vdmResp.vendorIdData = respMsg->data[2] << 8 |
                               respMsg->data[3];   // uint16_t Vendor ID Data
        vdmResp.commandSetType = respMsg->data[4] << 8 |
                                 respMsg->data[5]; // uint16_t Command Set Type

        vIdSelector = vdmResp.vendorIdSeSelector;

        /* Update VDM private params to export to upper layer */
        vdmTable.eid = eid;
        vdmTable.vendorId = vdmResp.vendorIdData;
        vdmTable.vIdSetSelector = vIdSelector;
        vdmTable.vendorIdSetCmdType = NULL;
        vdmTable.next = NULL;

        newCmdTypeNode.data = vdmResp.commandSetType;
        newCmdTypeNode.next = NULL;

        /* Create a new VDM entry and add to list */
        ret = mctpVdmEntryAdd(&vdmTable, &newCmdTypeNode);
        if (ret < 0)
        {
            mctpPrErr("%s: Failed to update global VDM table..", __func__);
            return -1;
        }

        /* Check if the next id exist.. */
        if (vIdSelector == 0xFF)
        {
            hasMoreEntries = false;
        }
        else
        {
            mctpPrDebug("%s : next entry is %x ", __func__, vIdSelector);
        }
    }
    return 0;
}

/**
 * @brief Delete endpoint and associated D-Bus objects
 * @param eid Endpoint ID to delete
 */
void deleteEndpoint(uint8_t eid)
{
    /// Delete dbus object for endpoint
    auto it = eidInterfaceMap.find(eid);
    if (it != eidInterfaceMap.end())
    {
        for (auto& iface : it->second)
        {
            server->remove_interface(iface);
        }
        mctpPrInfo("Unregistered endpoint EID=0x%02X from D-Bus", eid);
    }

    eidInterfaceMap.erase(eid);     // <-- remove from map!
    registeredEndpoints.erase(eid); // remove from registered endpoints
}

/**
 * @brief Delete invalid endpoints that are no longer in routing table
 * @param routing_entry_eids Set of valid routing entry EIDs
 * @param route_via_eid EID of the device to route via
 */
void deleteInvalidEndpoints(const std::unordered_set<uint8_t> routingEntryEids,
                            uint8_t routeviaEid)
{
    mctp_eid_t eid = 0;

    std::unordered_set<uint8_t> invalidEids;
    mctp_routing_table_t* entry;

    /// Get the start pointer
    entry = g_routing_table_entries;

    while (entry != NULL)
    {
        eid = entry->routingTable.startingEid;

        /// Find endpoints related to specific busowner
        if ((entry->routeVia == routeviaEid) && isEndpointRegistered(eid))
        {
            if (routingEntryEids.find(eid) == routingEntryEids.end())
            {
                mctpPrDebug("Deleting invalid endpoint: %x \n", eid);
                /// EID registered but not present in routing table, delete
                /// entry
                deleteEndpoint(eid);

                /// Delete route and neighbor via netlink
                deleteRouteAndNeighbor(entry->routeVia, eid);

                /// Mark for routing entry deletion
                invalidEids.insert(eid);
            }
        }
        entry = entry->next;
    }

    for (uint8_t eid : invalidEids)
    {
        /// Delete routing entry
        mctpRoutingEntryDelete(eid);
        /// Delete from global msg types
        mctpMsgTypeEntryRemove(eid);
        /// Delete from global uuids
        mctpUuidEntryRemove(eid);
    }
}

/**
 * @brief Get routing table entries from a device
 * @param device Reference to MctpDevice
 * @return 0 on success, -1 on failure
 */
int getRoutingTableEntries(MctpDevice& device)
{
    mctpPrInfo("Get RoutingTable Entries for EID:0x%02X", device.eid);
    uint8_t entry = 0x00;
    int rc;
    bool hasMoreEntries = true;
    uint8_t rxBuf[128];

    struct mctpCtrlCmdGetRoutingTable getRoutingTable;
    std::unordered_set<uint8_t> routingEntryEids;

    while (hasMoreEntries)
    {
        if (!mctpEncodeCtrlCmdGetRoutingTable(&getRoutingTable, entry))
        {
            mctpPrErr("%s mctp_encode_ctrl_cmd_get_routing_table failed ",
                      __func__);
            return -1;
        }

        size_t rxLen = sizeof(rxBuf);
        memset(rxBuf, 0x0, rxLen);

        rc = mctpCtrlSendRecv(reinterpret_cast<uint8_t*>(&getRoutingTable),
                              sizeof(getRoutingTable), rxBuf, &rxLen,
                              device.eid, 1000);
        if (rc < 0)
        {
            mctpPrErr("%s get_routing_table cmd failed", __func__);
            return -1;
        }

        struct mctpCtrlRespGetRoutingTable* routingTable =
            (struct mctpCtrlRespGetRoutingTable*)rxBuf;

        if (!mctpDecodeRespGetRoutingTable(routingTable))
        {
            mctpPrErr("%s: Packet parsing failed", __func__);
            return -1;
        }

        /* Check if the routing table exist */
        if (routingTable->numberOfEntries)
        {
            auto entries = routingTable->numberOfEntries;
            struct getRoutingTableEntry* nextRoutingTableEntry =
                (struct
                 getRoutingTableEntry*)((uint8_t*)rxBuf +
                                        sizeof(struct
                                               mctpCtrlRespGetRoutingTable));
            while (entries-- > 0)
            {
                struct getRoutingTableEntry routingTableEntry;

                /* Copy the routing table entries to local routing table */
                memcpy(&routingTableEntry, nextRoutingTableEntry,
                       sizeof(struct getRoutingTableEntry) -
                           (nextRoutingTableEntry->physAddressSize % 2));

                if (validateRoutingEntry(&routingTableEntry, device) ==
                    ROUTE_VALID)
                {
                    routingEntryEids.insert(routingTableEntry.startingEid);
                }

                nextRoutingTableEntry =
                    (struct
                     getRoutingTableEntry*)((uint8_t*)nextRoutingTableEntry +
                                            sizeof(
                                                struct getRoutingTableEntry) -
                                            nextRoutingTableEntry
                                                    ->physAddressSize %
                                                2);

                if (routingTableContainsEid(routingTableEntry.startingEid))
                {
                    continue;
                }

                rc = mctpRoutingEntryAdd(&routingTableEntry, device);
                if (rc < 0)
                {
                    mctpPrErr("%s: Failed to update global routing table..",
                              __func__);
                    return -1;
                }
            }
        }

        /* Check if the next routing table exist.. */
        if (routingTable->nextEntryHandle == 0xFF)
        {
            hasMoreEntries = false;
        }
        else
        {
            entry = routingTable->nextEntryHandle;
            mctpPrDebug("%s : next entry is %x ", __func__, entry);
        }
    }

    /// Delete invalid endpoints if any
    deleteInvalidEndpoints(routingEntryEids, device.eid);
    return 0;
}

/**
 * @brief Delete all endpoints and associated data structures
 */
void deleteEndpoints()
{
    /// Delete all D-Bus objects
    for (auto& [eid, interfaces] : eidInterfaceMap)
    {
        for (auto& iface : interfaces) // Note: non-const reference
        {
            if (iface)                 // Check if shared_ptr is valid
            {
                server->remove_interface(iface);
            }
        }
        mctpPrInfo("Unregistered endpoint EID=0x%02X from D-Bus", eid);
        /// Clear the vector to release all shared_ptr references
        interfaces.clear();
    }

    /// Clear the containers
    eidInterfaceMap.clear();
    registeredEndpoints.clear();

    DeviceRegistry deviceRegistry;
    mctp_routing_table_t* routeEntry;
    routeEntry = g_routing_table_entries;

    /// Delete routes from kernel
    while (routeEntry != NULL)
    {
        MctpDevice* dev = deviceRegistry.findByEid(routeEntry->routeVia);
        mctpPrDebug("%s: Deleting Route and neigh for eid: %d devIndex:%d ",
                    __func__, routeEntry->routingTable.startingEid,
                    dev->ifIndex);

        mctpNeighDel(routeEntry->routingTable.startingEid,
                     (const char*)dev->hwAddr, dev->ifIndex);
        mctpRouteDel(routeEntry->routingTable.startingEid, dev->ifIndex);
        routeEntry = routeEntry->next;
    }
    /// Delete all routing table entries and free associated memory
    mctpRoutingEntryDeleteAll();
    /// Delete uuid table entries
    mctpUuidDeleteAll();
    /// Delete msg type table entries
    mctpMsgTypesDeleteAll();
    /// Delete vdm type table entries
    mctpVdmDeleteAll();
}

/**
 * @brief Register endpoint on D-Bus with all required interfaces
 * @param eid Endpoint ID
 * @param uuid UUID string
 * @param msgTypes Vector of supported message types
 * @param vdmTypes Vector of supported VDM types
 * @param vendorId Vendor ID string
 * @param physicalBindingId Physical binding ID string
 * @param busNum Bus number
 * @param dynamic_addr Dynamic address
 */
void registerEndpoint(
    uint8_t eid, const std::string& uuid, std::vector<uint8_t> msgTypes,
    std::vector<uint16_t> vdmTypes, std::string& vendorId,
    std::string& physicalBindingId, int busNum, uint8_t dynamicAddr)
{
    std::vector<std::shared_ptr<sdbusplus::asio::dbus_interface>> ifaces;
    std::string path = "/xyz/openbmc_project/mctp/" + std::to_string(busNum) +
                       "/" + std::to_string(eid);

    auto uuidIface = server->add_interface(path, MCTP_CTRL_DBUS_UUID_INTERFACE);
    uuidIface->register_property("UUID", uuid);
    uuidIface->initialize();
    ifaces.push_back(uuidIface);

    auto epIface = server->add_interface(path, MCTP_CTRL_DBUS_EP_INTERFACE);
    epIface->register_property("EID", static_cast<uint32_t>(eid));
    epIface->register_property(
        "MediumType",
        std::string{"xyz.openbmc_project.MCTP.Endpoint.MediumType.I3C"});
    epIface->register_property("NetworkId", MCTP_I3C_NET);
    epIface->register_property("SupportedMessageTypes", msgTypes);
    epIface->initialize();
    ifaces.push_back(epIface);

    auto vdmIface = server->add_interface(path, MCTP_CTRL_DBUS_VDM_INTERFACE);
    vdmIface->register_property("MessageTypeProperty", vdmTypes);
    vdmIface->register_property("VendorId", vendorId);
    vdmIface->initialize();
    ifaces.push_back(vdmIface);

    auto devIface =
        server->add_interface(path, MCTP_CTRL_DBUS_DECORATOR_INTERFACE);
    devIface->register_property("Address", dynamicAddr);
    devIface->register_property("Bus", busNum);
    devIface->initialize();
    ifaces.push_back(devIface);

    auto bindingIface =
        server->add_interface(path, MCTP_CTRL_DBUS_BINDING_INTERFACE);
    bindingIface->register_property("BindingType", physicalBindingId);
    bindingIface->initialize();
    ifaces.push_back(bindingIface);

#ifdef CLIENT_SOCKET_INTERFACE
    auto clientSocketIface =
        server->add_interface(path, MCTP_CTRL_DBUS_SOCK_INTERFACE);

    clientSocketIface->register_property("Type",
                                         static_cast<uint32_t>(SOCK_SEQPACKET));

    clientSocketIface->register_property("Protocol", static_cast<uint32_t>(0));

    // Register 'Address' property as array of bytes using std::string
    std::string sockPath = "/tmp/mctp-i3c-sock-mux";
    std::vector<uint8_t> sockAddrBytes(sockPath.begin(), sockPath.end());
    clientSocketIface->register_property("Address", sockAddrBytes);

    clientSocketIface->initialize();
    ifaces.push_back(clientSocketIface);
#endif

    eidInterfaceMap.insert({eid, ifaces});

    mctpPrInfo("Registered endpoint EID=0x%02X on D-Bus path=%s", eid,
               path.c_str());
}

/**
 * @brief Register D-Bus objects for endpoints from routing table
 * @return 0 on success, -1 on failure
 */
int registerRoutingTableEndpoints()
{
    char vendorIdStr[MCTP_CTRL_SDBUS_NAME_SIZE] = {0};
    char physicalBindingId[MCTP_CTRL_SDBUS_NAME_SIZE] = {0};
    std::string vendorId;

    if (g_routing_table_entries == NULL)
    {
        mctpPrInfo("No routing entries to register endpoints");
        return -1;
    }

    mctp_routing_table_t* tempEntry = g_routing_table_entries;
    while (tempEntry != NULL)
    {
        auto eid = tempEntry->routingTable.startingEid;
        /** Skip registering already registered endpoints */
        if (registeredEndpoints.find(eid) != registeredEndpoints.end())
        {
            tempEntry = tempEntry->next;
            continue;
        }

        if (tempEntry->valid)
        {
            /** Get UUID string */
            mctpUuidTable_t* uuidEntry = g_uuid_entries;
            std::string uuidStr = "00000000-0000-0000-0000-000000000000";
            while (uuidEntry != NULL)
            {
                if (uuidEntry->eid == eid)
                {
                    char buf[37];
                    snprintf(
                        buf, sizeof(buf),
                        "%02x%02x%02x%02x-%02x%02x-%02x%02x-%02x%02x-%02x%02x%02x%02x%02x%02x",
                        uuidEntry->uuid[0], uuidEntry->uuid[1],
                        uuidEntry->uuid[2], uuidEntry->uuid[3],
                        uuidEntry->uuid[4], uuidEntry->uuid[5],
                        uuidEntry->uuid[6], uuidEntry->uuid[7],
                        uuidEntry->uuid[8], uuidEntry->uuid[9],
                        uuidEntry->uuid[10], uuidEntry->uuid[11],
                        uuidEntry->uuid[12], uuidEntry->uuid[13],
                        uuidEntry->uuid[14], uuidEntry->uuid[15]);
                    uuidStr = std::string(buf);
                    break;
                }
                uuidEntry = uuidEntry->next;
            }

            /** Get bus number and dynamic address */
            int busNum = 0;
            uint8_t dynamicAddr = 0;

            auto routeEid = tempEntry->routeVia;
            for (const auto& dev : DeviceRegistry::devices)
            {
                if (dev.eid == routeEid)
                {
                    busNum = dev.busNumber;
                    dynamicAddr = dev.dynamicAddr;
                    break;
                }
            }

            /** Get message types */
            std::vector<uint8_t> msgTypes;
            mctpMsgTypeTable_t* msgEntry = g_msg_type_entries;
            while (msgEntry != NULL)
            {
                if (msgEntry->eid == eid)
                {
                    for (int i = 0; i < msgEntry->dataLen; i++)
                    {
                        msgTypes.push_back(msgEntry->data[i]);
                    }
                    break;
                }
                msgEntry = msgEntry->next;
            }
            msgTypes.push_back(0x00); // Add MCTP Control Message type

            /** Get VDM types */
            std::vector<uint16_t> vdmTypes;
            mctpVdmTable_t* vdmEntry = g_vdm_entries;
            while (vdmEntry != NULL)
            {
                if (vdmEntry->eid == eid)
                {
                    vendorIdSetCmdTypeNode_t* cmdEntry =
                        vdmEntry->vendorIdSetCmdType;
                    while (cmdEntry != NULL)
                    {
                        vdmTypes.push_back(cmdEntry->data);
                        cmdEntry = cmdEntry->next;
                    }

                    snprintf(vendorIdStr, sizeof(vendorIdStr), "0x%04x",
                             vdmEntry->vendorId);

                    vendorId = std::string(vendorIdStr);
                    break;
                }
                vdmEntry = vdmEntry->next;
            }

            /**
             * SMbus 400K is running but the medium type in the spec. only
             * indicates SMbus 100K. So the medium type is I2C 400K reported by
             * FPGA from MCTP service. We used physical transport identifier to
             * populate D-Bus property.
             */
            uint8_t bindId = tempEntry->routingTable.physTransportBindingId;
            const char* bindingTypeStr = phyTransportBindingToString(bindId);
            if (!bindingTypeStr)
            {
                bindingTypeStr = "Unknown";
            }
            snprintf(physicalBindingId, sizeof(physicalBindingId),
                     "xyz.openbmc_project.MCTP.Endpoint.MediaTypes.%s",
                     bindingTypeStr);

            std::string physicalBindingIdStr(physicalBindingId);

            /** Register endpoint */
            registerEndpoint(eid, uuidStr, msgTypes, vdmTypes, vendorId,
                             physicalBindingIdStr, busNum, dynamicAddr);
            /**
             * Each EID is mapped to its routeVia; multiple EIDs can share the
             * same routeVia if needed. This is intentional and supported by
             * the current implementation.
             */
            registeredEndpoints.insert({eid, tempEntry->routeVia});
        }
        tempEntry = tempEntry->next;
    }
    return 0;
}
