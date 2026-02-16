#include "mctp-encode.hpp"

#include "mctp-app-log.hpp"

/**
 * @brief Create a unique instance ID for MCTP control messages
 * @return Next instance ID with proper masking
 */
static uint8_t createInstanceId()
{
    static uint8_t instanceId = 0x00;

    instanceId = (instanceId + 1) & MCTP_CTRL_HDR_INSTANCE_ID_MASK;
    return instanceId;
}

/**
 * @brief Get request datagram instance with request flag
 * @return Instance ID with request flag set
 */
static uint8_t getRqDgramInst()
{
    uint8_t instanceID = createInstanceId();
    uint8_t rqDgramInst = instanceID | MCTP_CTRL_HDR_FLAG_REQUEST;
    return rqDgramInst;
}

/**
 * @brief Encode MCTP control command header
 * @param mctpCtrlHdr Pointer to control message header
 * @param rqDgramInst Request datagram instance
 * @param cmdCode Command code
 */
static void encodeCtrlCmdHeader(struct mctpCtrlCmdMsgHdr* mctpCtrlHdr,
                                uint8_t rqDgramInst, uint8_t cmdCode)
{
    mctpCtrlHdr->rqDgramInst = rqDgramInst;
    mctpCtrlHdr->commandCode = cmdCode;
}

/**
 * @brief Encode Get Routing table request
 * @param getRoutingTableCmd Pointer to routing table command structure
 * @param entryHandle Entry handle for the routing table request
 * @return true on success, false if command structure is null
 */
bool mctpEncodeCtrlCmdGetRoutingTable(
    struct mctpCtrlCmdGetRoutingTable* getRoutingTableCmd, uint8_t entryHandle)
{
    if (!getRoutingTableCmd)
        return false;

    encodeCtrlCmdHeader(&getRoutingTableCmd->ctrlMsgHdr, getRqDgramInst(),
                        MCTP_CMD_GET_ROUTING_TABLE);
    getRoutingTableCmd->entryHandle = entryHandle;
    return true;
}

/**
 * @brief Encode MCTP Discovery Notify command
 * @param discoverNotifyCmd Pointer to discovery notify command structure
 * @return true on success, false if command structure is null
 */
bool mctpEncodeCtrlCmdDiscoveryNotify(
    struct mctpCtrlCmdDiscoveryNotify* discoverNotifyCmd)
{
    if (!discoverNotifyCmd)
        return false;

    encodeCtrlCmdHeader(&discoverNotifyCmd->ctrlHdr, getRqDgramInst(),
                        MCTP_CMD_DIS_NOTIFY);
    return true;
}

/**
 * @brief Encode Get Version Support command
 * @param mctpVerSupportCmd Pointer to version support command structure
 * @param msgTypeNumber Message type number
 * @return true on success, false if command structure is null
 */
bool mctpEncodeCtrlCmdGetVerSupport(
    struct mctpCtrlCmdGetMctpVerSupport* mctpVerSupportCmd,
    uint8_t msgTypeNumber)
{
    if (!mctpVerSupportCmd)
        return false;

    encodeCtrlCmdHeader(&mctpVerSupportCmd->ctrlMsgHdr, getRqDgramInst(),
                        MCTP_CMD_GET_VERSION_SUPPORT);
    mctpVerSupportCmd->msgTypeNumber = msgTypeNumber;
    return true;
}

/**
 * @brief Encode Get UUID command
 * @param getUuidCmd Pointer to get UUID command structure
 * @return true on success, false if command structure is null
 */
bool mctpEncodeCtrlCmdGetUuid(struct mctpCtrlCmdGetUuid* getUuidCmd)
{
    if (!getUuidCmd)
        return false;

    encodeCtrlCmdHeader(&getUuidCmd->ctrlMsgHdr, getRqDgramInst(),
                        MCTP_CMD_GET_UUID);
    return true;
}

/**
 * @brief Encode Get Message Type command
 * @param getMsgTypeCmd Pointer to get message type command structure
 * @return true on success, false if command structure is null
 */
bool mctpEncodeCtrlCmdGetMsgType(
    struct mctpCtrlCmdGetMsgTypeSupport* getMsgTypeCmd)
{
    if (!getMsgTypeCmd)
        return false;

    encodeCtrlCmdHeader(&getMsgTypeCmd->ctrlMsgHdr, getRqDgramInst(),
                        MCTP_GET_MSG_TYPE);
    return true;
}

/**
 * @brief Encode Get EID command
 * @param getEidCmd Pointer to get EID command structure
 * @return true on success, false if command structure is null
 */
bool mctpEncodeCtrlCmdGetEid(struct mctpCtrlCmdGetEid* getEidCmd)
{
    if (!getEidCmd)
        return false;

    encodeCtrlCmdHeader(&getEidCmd->ctrlMsgHdr, getRqDgramInst(),
                        MCTP_CMD_GET_EID);
    return true;
}

/**
 * @brief Encode Set EID command
 * @param setEidCmd Pointer to set EID command structure
 * @param setOperation Set operation type
 * @param setEid EID value to set
 * @return true on success, false if command structure is null
 */
bool mctpEncodeCtrlCmdSetEid(struct mctpCtrlCmdSetEid* setEidCmd,
                             uint8_t setOperation, uint8_t setEid)
{
    if (!setEidCmd)
        return false;

    encodeCtrlCmdHeader(&setEidCmd->ctrlHdr, getRqDgramInst(),
                        MCTP_CMD_SET_EID);
    setEidCmd->operation = setOperation;
    setEidCmd->eid = setEid;
    return true;
}

/**
 * @brief Encode Get MCTP Version command
 * @param getMctpVerCmd Pointer to get MCTP version command structure
 * @return true on success, false if command structure is null
 */
bool mctpEncodeCtrlCmdGetMctpVersion(
    struct mctpCtrlCmdGetMctpVerSupport* getMctpVerCmd)
{
    if (!getMctpVerCmd)
        return false;

    encodeCtrlCmdHeader(&getMctpVerCmd->ctrlMsgHdr, getRqDgramInst(),
                        MCTP_CMD_GET_VERSION_SUPPORT);
    return true;
}

/**
 * @brief Encode Get VDM Support command
 * @param getVdmSupport Pointer to get VDM support command structure
 * @param selector Vendor ID set selector
 * @return true on success, false if command structure is null
 */
bool mctpEncodeCtrlCmdGetVdmSupport(
    struct mctpCtrlCmdGetVdmSupport* getVdmSupport, uint8_t selector)
{
    if (!getVdmSupport)
        return false;

    encodeCtrlCmdHeader(&getVdmSupport->ctrlMsgHdr, getRqDgramInst(),
                        MCTP_CMD_GET_VENDOR_MESSAGE_SUPPORT);
    getVdmSupport->vendorIdSeSelector = selector;

    return true;
}

/**
 * @brief Decode Get Routing Table response
 * @param routingTable Pointer to routing table response structure
 * @return true on success, false if structure is null or completion code
 * indicates failure
 */
bool mctpDecodeRespGetRoutingTable(
    struct mctpCtrlRespGetRoutingTable* routingTable)
{
    if (!routingTable)
        return false;

    if (routingTable->completionCode != MCTP_CTRL_CC_SUCCESS)
        return false;

    mctpPrDebug("nextEntryHandle: %d, numberOfEntries: %d",
                routingTable->nextEntryHandle, routingTable->numberOfEntries);

    return true;
}

/**
 * @brief Decode Get VDM Support control command response
 * @param getVdmResp Pointer to get VDM response structure
 * @return true on success, false if structure is null or completion code
 * indicates failure
 */
bool mctpDecodeCtrlCmdGetVdmSupport(
    struct mctpPciCtrlRespGetVdmSupport* getVdmResp)
{
    if (!getVdmResp)
        return false;

    if (getVdmResp->completionCode != MCTP_CTRL_CC_SUCCESS)
        return false;

    return true;
}

/**
 * @brief Decode Get UUID response
 * @param getUuidResp Pointer to get UUID response structure
 * @return true on success, false if structure is null or completion code
 * indicates failure
 */
bool mctpDecodeRespGetUuid(struct mctpCtrlRespGetUuid* getUuidResp)
{
    if (!getUuidResp)
        return false;

    if (getUuidResp->completionCode != MCTP_CTRL_CC_SUCCESS)
        return false;

    return true;
}

/**
 * @brief Decode Get Message Type response
 * @param getMsgTypeResp Pointer to get message type response structure
 * @return true on success, false if structure is null or completion code
 * indicates failure
 */
bool mctpDecodeRespGetMsgType(
    struct mctpCtrlRespGetMsgTypeSupport* getMsgTypeResp)
{
    if (!getMsgTypeResp)
        return false;

    if (getMsgTypeResp->completionCode != MCTP_CTRL_CC_SUCCESS)
        return false;

    return true;
}
