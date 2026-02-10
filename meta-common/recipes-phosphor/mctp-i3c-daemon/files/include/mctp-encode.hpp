
#ifndef MCTP_ENCODE_HPP
#define MCTP_ENCODE_HPP

#include <cstdint>

#define MCTP_TYPE_CONTROL 0x00 // MCTP Control Message Type
#define MCTP_ADDR_ANY 0xff
#define MCTP_CMD_GET_EID 0x02
#define MCTP_CMD_SET_EID 0x01
#define MCTP_CMD_DIS_NOTIFY 0x0D
#define MCTP_CMD_GET_ROUTING_TABLE 0x0A
#define MCTP_CMD_GET_UUID 0x03
#define MCTP_CMD_GET_VENDOR_MESSAGE_SUPPORT 0x06
#define MCTP_CMD_GET_VERSION_SUPPORT 0x04
#define MCTP_CMD_ALLOC_POOL_ID 0x08
#define MCTP_GET_EP_UUID 0x03
#define MCTP_GET_MSG_TYPE 0x05
#define MCTP_ROUTING_INFO_UPDATE 0x09

/* Baseline Transmission Unit and packet size */
#define MCTP_BTU 64
#define MCTP_MSG_TYPE_MAX_SIZE 0xFF

#define MCTP_CTRL_HDR_FLAG_REQUEST (1 << 7)
#define MCTP_CTRL_HDR_INSTANCE_ID_MASK 0x1F

#define MCTP_CTRL_CC_SUCCESS 0x00

/* Define mctp_eid_t as uint8_t */
typedef uint8_t mctp_eid_t;

struct getRoutingTableEntry
{
    uint8_t eidRangeSize;
    uint8_t startingEid;
    uint8_t entryType;
    uint8_t physTransportBindingId;
    uint8_t physMediaTypeId;
    uint8_t physAddressSize;
    uint8_t physAddress[2];
} __attribute__((__packed__));

typedef struct mctpRoutingTable
{
    int id;
    bool valid;
    uint8_t routeVia;
    struct getRoutingTableEntry routingTable;
    struct mctpRoutingTable* next;
} mctp_routing_table_t;

struct mctpCtrlCmdMsgHdr
{
    uint8_t rqDgramInst;
    uint8_t commandCode;
} __attribute__((__packed__));

struct mctpCtrlCmdGetVdmSupport
{
    struct mctpCtrlCmdMsgHdr ctrlMsgHdr;
    uint8_t vendorIdSeSelector;
} __attribute__((__packed__));

struct mctpCtrlRespGetVdmSupport
{
    struct mctpCtrlCmdMsgHdr ctrlMsgHdr;
    uint8_t completionCode;
    uint8_t vendorIdSeSelector;
    uint8_t vendorIdFormat;
    union
    {
        uint16_t vendorIdDataPcie;
        uint32_t vendorIdDataIana;
    };
    /* following bytes are dependent on vendor id format
     * and shall be interpreted by appropriate binding handler */
} __attribute__((__packed__));

/* Structure for Getting MCTP response */
struct mctpCtrlResp
{
    struct mctpCtrlCmdMsgHdr hdr;
    uint8_t completionCode;
    uint8_t data[MCTP_BTU];
} __attribute__((__packed__));

struct mctpCtrlRespGetRoutingTable
{
    struct mctpCtrlCmdMsgHdr ctrlHdr;
    uint8_t completionCode;
    uint8_t nextEntryHandle;
    uint8_t numberOfEntries;
} __attribute__((__packed__));

struct mctpCtrlCmdGetRoutingTable
{
    struct mctpCtrlCmdMsgHdr ctrlMsgHdr;
    uint8_t entryHandle;
} __attribute__((__packed__));

struct mctpCtrlCmdGetUuid
{
    struct mctpCtrlCmdMsgHdr ctrlMsgHdr;
} __attribute__((__packed__));

struct mctpCtrlCmdGetEid
{
    struct mctpCtrlCmdMsgHdr ctrlMsgHdr;
} __attribute__((__packed__));

struct mctpCtrlRespGetUuid
{
    struct mctpCtrlCmdMsgHdr ctrlHdr;
    uint8_t completionCode;
    uint8_t uuid[16];
} __attribute__((__packed__));

struct mctpCtrlCmdGetMsgTypeSupport
{
    struct mctpCtrlCmdMsgHdr ctrlMsgHdr;
} __attribute__((__packed__));

struct mctpCtrlRespGetMsgTypeSupport
{
    struct mctpCtrlCmdMsgHdr ctrlHdr;
    uint8_t completionCode;
    uint8_t msgTypeCount;
    uint8_t msgTypesSupported; // TODO icrease the size to 0xFF
} __attribute__((__packed__));

struct mctpCtrlCmdGetMctpVerSupport
{
    struct mctpCtrlCmdMsgHdr ctrlMsgHdr;
    uint8_t msgTypeNumber;
} __attribute__((__packed__));

/* List for MCTP Message types */
typedef struct mctpMsgTypeTable
{
    uint8_t eid;
    uint16_t dataLen;
    uint8_t data[MCTP_MSG_TYPE_MAX_SIZE];
    struct mctpMsgTypeTable* next;
} mctpMsgTypeTable_t;

/* List for UUIDs */
typedef struct mctpUuidTable
{
    uint8_t eid;
    uint8_t uuid[16];
    struct mctpUuidTable* next;
} mctpUuidTable_t;

struct mctpPciCtrlRespGetVdmSupport
{
    struct mctpCtrlCmdMsgHdr ctrlHdr;
    uint8_t completionCode;
    uint8_t vendorIdSeSelector;
    uint8_t vendorIdFormat;
    uint16_t vendorIdData;
    uint16_t commandSetType;
} __attribute__((__packed__));

typedef struct vendorIdSetCmdTypeNode
{
    uint16_t data;
    struct vendorIdSetCmdTypeNode* next;
} vendorIdSetCmdTypeNode_t;

/* List for VDMs */
typedef struct mctpVdmTable
{
    uint8_t eid;
    uint16_t vendorId;
    uint8_t vIdSetSelector;
    vendorIdSetCmdTypeNode_t* vendorIdSetCmdType;
    struct mctpVdmTable* next;
} mctpVdmTable_t;

struct mctpCtrlCmdDiscoveryNotify
{
    struct mctpCtrlCmdMsgHdr ctrlHdr;
} __attribute__((__packed__));

struct mctpCtrlRespDiscoveryNotify
{
    struct mctpCtrlCmdMsgHdr ctrlHdr;
    uint8_t completionCode;
} __attribute__((__packed__));

struct mctpCtrlRespGetEid
{
    struct mctpCtrlCmdMsgHdr ctrlHdr;
    uint8_t completionCode;
    mctp_eid_t eid;
    uint8_t eidType;
    uint8_t mediumData;

} __attribute__((__packed__));

struct mctpCtrlCmdSetEid
{
    struct mctpCtrlCmdMsgHdr ctrlHdr;
    uint8_t operation;
    uint8_t eid;
} __attribute__((__packed__));

struct mctpCtrlRespSetEid
{
    struct mctpCtrlCmdMsgHdr ctrlHdr;
    uint8_t completionCode;
    uint8_t status;
    mctp_eid_t eidSet;
    uint8_t eidPoolSize;
} __attribute__((__packed__));

struct mctpCtrlCmdAllocEid
{
    struct mctpCtrlCmdMsgHdr ctrlHdr;
    uint8_t operation;
    uint8_t NoOfEids;
    uint8_t eidStart;
} __attribute__((__packed__));

typedef enum
{
    alloc_resp_accepted,
    alloc_resp_rejected,
    alloc_resp_resvd,
} mctpCtrlRespAllocEidOp;

struct mctpCtrlRespAllocEid
{
    struct mctpCtrlCmdMsgHdr ctrlHdr;
    uint8_t completionCode;
    uint8_t allocStatus:2;
    uint8_t eidPoolSize;
    uint8_t eidStart;
} __attribute__((__packed__));

struct mctpCtrlRespRoutingUpdate
{
    struct mctpCtrlCmdMsgHdr ctrlHdr;
    uint8_t completionCode;
} __attribute__((__packed__));

bool mctpEncodeCtrlCmdGetRoutingTable(
    struct mctpCtrlCmdGetRoutingTable* getRoutingTableCmd, uint8_t entryHandle);

bool mctpEncodeCtrlCmdDiscoveryNotify(
    struct mctpCtrlCmdDiscoveryNotify* discoverNotifyCmd);

bool mctpEncodeCtrlCmdGetVerSupport(
    struct mctpCtrlCmdGetMctpVerSupport* mctpVerSupportCmd,
    uint8_t msgTypeNumber);

bool mctpEncodeCtrlCmdGetUuid(struct mctpCtrlCmdGetUuid* getUuidCmd);

bool mctpEncodeCtrlCmdGetMsgType(
    struct mctpCtrlCmdGetMsgTypeSupport* getMsgTypeCmd);

bool mctpEncodeCtrlCmdGetEid(struct mctpCtrlCmdGetEid* getEidCmd);

bool mctpEncodeCtrlCmdSetEid(struct mctpCtrlCmdSetEid* setEidCmd,
                             uint8_t setOperation, uint8_t setEid);

bool mctpEncodeCtrlCmdGetMctpVersion(
    struct mctpCtrlCmdGetMctpVerSupport* getMctpVerCmd);

bool mctpEncodeCtrlCmdGetVdmSupport(
    struct mctpCtrlCmdGetVdmSupport* getVdmSupport, uint8_t selector);

bool mctpDecodeRespGetRoutingTable(
    struct mctpCtrlRespGetRoutingTable* routingTable);

bool mctpDecodeCtrlCmdGetVdmSupport(
    struct mctpPciCtrlRespGetVdmSupport* getVdmResp);

bool mctpDecodeRespGetUuid(struct mctpCtrlRespGetUuid* getUuidResp);

bool mctpDecodeRespGetMsgType(
    struct mctpCtrlRespGetMsgTypeSupport* getMsgTypeResp);

#endif // MCTP_ENCODE_HPP
