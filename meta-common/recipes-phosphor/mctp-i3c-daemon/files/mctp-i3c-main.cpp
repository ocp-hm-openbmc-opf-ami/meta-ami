/**
 * @file mctp-i3c-main.cpp
 * @brief Main entry point for the MCTP I3C Application.
 *
 * This application implements an MCTP (Management Component Transport Protocol)
 * responder using Boost.Asio for asynchronous I/O and sdbusplus for D-Bus
 * integration. It manages device discovery, endpoint configuration, routing
 * table management, and handles MCTP control commands over I3C interfaces. The
 * application is configured via a JSON file specifying device roles and bus
 * mappings.
 *
 * Usage:
 *   mctp-i3c-daemon -c <config.json> [-m <mode>] [-p <pool_eid>]
 *
 * Responsibilities:
 *   - Parse configuration and initialize device registry.
 *   - Set up MCTP sockets and handle incoming control commands.
 *   - Manage device discovery and routing table updates.
 *   - Integrate with D-Bus for system state monitoring and property changes.
 *   - Provide asynchronous event handling for timers and signals.
 */

#include "DebugFileMonitor.hpp"
#include "MctpDevice.hpp"
#include "mctp-ctrl-cmds.hpp"
#include "mctp-encode.hpp"
#include "mctp-i3c-client-sock.hpp"
#include "utils.hpp"

#include <sys/socket.h>

#include <boost/algorithm/string/predicate.hpp>
#include <boost/asio/io_context.hpp>
#include <boost/asio/posix/stream_descriptor.hpp>
#include <boost/asio/post.hpp>
#include <boost/asio/signal_set.hpp>
#include <boost/asio/steady_timer.hpp>
#include <sdbusplus/asio/connection.hpp>
#include <sdbusplus/asio/object_server.hpp>
#include <sdbusplus/bus/match.hpp>

using namespace boost::asio;
using namespace std::chrono_literals;

#define ENTRY_COUNT_OFFSET 4

/// @brief Global I/O context for Boost.Asio
io_context io;

/// @brief Unique pointer for MCTP socket descriptor
std::unique_ptr<posix::stream_descriptor> mctpSocket;

/// @brief Unique pointer for Client socket descriptor
std::unique_ptr<posix::stream_descriptor> clientSocket;

/// @brief Unique pointer for steady timer
std::unique_ptr<steady_timer> timer;

/// @brief Signal set for handling termination signals
signal_set signals(io, SIGTERM, SIGABRT);

/// @brief Global pointer for Routing table and its length
mctp_routing_table_t* g_routing_table_entries = NULL;
int g_routing_table_length = 0;

/// @brief Global pointer for UUID and its length
mctpUuidTable_t* g_uuid_entries = NULL;
int g_uuid_table_len = 0;

/// @brief Global pointer for Message types and its length
mctpMsgTypeTable_t* g_msg_type_entries = NULL;
int g_msg_type_table_len = 0;

/// @brief Global pointer for VDM and its length
mctpVdmTable_t* g_vdm_entries = NULL;
int g_vdm_table_len = 0;

/// @brief  Global pointer for DebugFileMonitor
std::unique_ptr<DebugFileMonitor> g_debug_monitor;

std::string g_config_file;

std::shared_ptr<sdbusplus::asio::connection> conn;
std::unique_ptr<sdbusplus::asio::object_server> server;

DeviceRegistry deviceRegistry;

int ifIndex = -1;
int MCTP_I3C_NET = 1;

bool eidPoolAssigned = false;
bool initialDiscoveryDone = false;
bool supress = false;
bool secondaryBusOwnerDiscoveryNotifySent = false;
bool skipIteration = false;

uint8_t startEid = 0x08; // Default starting EID
uint8_t eidPoolStartEid;
uint8_t eidPoolsize = 0;
uint8_t PstartEid = 0;

int mode;

/// @brief Default local EID for Bus Owner mode
uint8_t busownerLocalEid = 0x0C;

/// @brief Default local EID for Endpoint mode
uint8_t defaultEndpointLocalEid = 0x09;

// Initialize debug file monitoring
int initDebugMonitor(boost::asio::io_context& io)
{
    g_debug_monitor =
        std::make_unique<DebugFileMonitor>(io, "/var/run", "mctp_trace_on");

    return g_debug_monitor->start();
}

// Cleanup debug file monitoring
void cleanupDebugMonitor()
{
    if (g_debug_monitor)
    {
        g_debug_monitor->stop();
        g_debug_monitor = nullptr;
    }
}

/// @brief Fill the response header for MCTP control command messages
/// @param hdr Reference to the header structure to be filled
/// @param rq_inst Instance ID for the request
/// @param cmd Command code for the message
inline void mctpFillRespHdr(struct mctpCtrlCmdMsgHdr& hdr, uint8_t rqInst,
                            uint8_t cmd)
{
    hdr.rqDgramInst = rqInst; // Instance ID
    hdr.commandCode = cmd;    // Command code
}

/**
 * @brief Initiates device discovery for a given endpoint device.
 *
 * @param device Reference to the MctpDevice object representing the endpoint.
 * @param eid The EID (Endpoint ID) to be assigned or used for the device.
 * @return int Returns 0 on success, or a negative error code on failure.
 */
int initEndpointDiscovery(MctpDevice& device, uint8_t eid)
{
    int rc = 0;
    mctpPrInfo("Initiate Device Discovery for EID:0x%02X index:%d", eid,
               device.ifIndex);

    rc = getMctpVersion(device);
    if (rc < 0)
    {
        mctpPrErr("%s: get_mctp_ver fn failed ", __func__);
        return rc;
    }

    rc = getEid(device, eid);
    if (rc < 0)
    {
        mctpPrErr("%s: get_eid fn failed ", __func__);
        return rc;
    }
    else if (rc) // EID matches, device already has the expected EID
    {
        return 1;
    }

    if (!isEidValid(device.staticEid))
    {
        rc = setEid(device, eid);
        if (rc < 0)
        {
            mctpPrErr("%s: setEid fn failed , exiting device discovery",
                      __func__);
            return rc;
        }
    }
    else
    {
        rc = addRoute(device.staticEid, device.hwAddr, device.ifIndex);
        if (rc < 0)
        {
            mctpPrErr("adding pfr route cmd failed ");
            return rc;
        }
        device.eid = device.staticEid;
    }

    if (device.isMctpBridge)
    {
        mctpPrInfo(
            "endpoint device is bridge, calling get routing table entries 0x%x",
            eid);
        rc = getRoutingTableEntries(device);
        if (rc < 0)
        {
            mctpPrErr("%s: get_routing_table_entries fn failed ", __func__);
        }
    }

    if (mode == MCTP_BUSOWNER || mode == MCTP_INTEL_I3C_BRIDGE)
    {
        // Add entry to routing table
        if (!routingTableContainsEid(eid))
        {
            struct getRoutingTableEntry epEntry;
            epEntry.eidRangeSize = 0x01;
            epEntry.startingEid = eid;             // PFR EID
            epEntry.entryType = 0x00;              // Single endpoint
            epEntry.physTransportBindingId = 0x06; // I3C 3.4MHz
            epEntry.physMediaTypeId = 0x30;        // I3C compatible
            epEntry.physAddressSize = 0x01;
            epEntry.physAddress[0] = 0x00;
            epEntry.physAddress[1] = 0x00;

            // Add entry
            mctpRoutingEntryAdd(&epEntry, device);
        }
    }

    return rc;
}

/**
 * @brief Initializes MCTP local interfaces and addresses.
 *
 * This function sets up the local EIDs (Endpoint IDs) for devices in the
 * device registry based on their roles (BusOwner or Endpoint) and configures
 * the local EID for each device.
 *
 * @return int Returns 0 on success, or a negative error code on failure.
 */
int mctpSetupLocalInterfaces()
{
    mctpPrInfo("initialising mctp local interface(s) and addr(s)");
    int rc;

    for (auto& device : deviceRegistry.devices)
    {
        // Skip controller devices that were not detected during bus scanning
        if (device.isController && !device.detected)
        {
            mctpPrInfo(
                "Skipping interface setup for undetected controller device: %s",
                device.name.c_str());
            continue;
        }

        if (device.role == "BusOwner")
        {
            device.localEid = defaultEndpointLocalEid;
        }
        else if (device.role == "Endpoint")
        {
            device.localEid = busownerLocalEid;
        }

        // Assign local address for BMC
        rc = configureLocalEid(device.localEid, device.ifIndex, MCTP_I3C_NET);
        if (rc < 0)
        {
            mctpPrErr("configureLocalEid bo failed");
            return rc;
        }
    }
    return 0;
}

/**
 * @brief Executes the device discovery workflow for MCTP devices.
 *
 * This function iterates through the device registry and performs the
 * following:
 * - For devices with the role "Endpoint", it initiates asynchronous device
 * discovery based on their static EID or assigns a new EID if not valid.
 * - For devices with the role "BusOwner", it sends a discovery notification.
 *
 * @return int Returns 0 on success, or a negative error code on failure.
 */
int mctpDeviceDiscoveryWorkflow()
{
    int rc;
    for (MctpDevice& device : deviceRegistry.devices)
    {
        // Skip controller devices that were not detected during bus scanning
        if (device.isController && !device.detected)
        {
            mctpPrInfo(
                "Skipping device discovery for undetected controller device: %s (PID 0x%04X)",
                device.name.c_str(), device.pidMask);
            continue;
        }

        if (device.role == "Endpoint")
        {
            uint8_t eid;

            if ((mode != MCTP_INTEL_I3C_BRIDGE) &&
                !isEidValid(device.staticEid))
            {
                eid = startEid++;
            }
            else if (isEidValid(device.staticEid))
            {
                eid = device.staticEid;
            }
            else
            {
                continue; // Skip this device if neither condition is met
            }

            // Post timer work to io_context so device discovery will run in
            // background
            post(io, [&device, eid] {
                mctpPrInfo("start async device discovery");
                int retryCount = 0;
                while (retryCount < 3)
                {
                    // Allow D-Bus events to be processed if callback is set
                    if (processEventsCallback)
                    {
                        processEventsCallback();
                    }
                    if (initEndpointDiscovery(device, eid) >= 0)
                    {
                        mctpPrInfo(
                            "initEndpointDiscovery success for EID:0x%02X",
                            eid);
                        registerRoutingTableEndpoints();
                        break;
                    }
                    mctpPrInfo("Retrying Discovery for EID:0x%02X", eid);
                    retryCount++;
                }
            });
        }

        if ((device.role == "BusOwner") && !device.isSecondaryBusOwner)
        {
            rc = sendDiscoveryNotify(device);
            if (rc < 0)
            {
                mctpPrErr("sendDiscoveryNotify failed");
                return rc;
            }
        }
    }
    return 0;
}

/// @brief Async MCTP responder
/// @param ec Boost system error code
void handleMctpControlCommand(const boost::system::error_code& ec)
{
    uint8_t cmdCode = 0;
    uint8_t* rxbuf = nullptr;
    int ret, sendLen = -1;
    int entries_count = 0;
    char buffer[128];
    char ownUuid[32] = {0x80, 0x00, 0x86, 0x00, 0x04, 0x00, 0x00, 0x40,
                        0x80, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00};

    ssize_t recvLen = 0;
    size_t len = 0;
    struct sockaddr_mctp_ext srcAddr;
    memset(&srcAddr, 0x0, sizeof(srcAddr));
    socklen_t srcAddrLen = 0;
    srcAddrLen = sizeof(srcAddr);

    bool debugEnabled = false;
    bool fromSecondaryBusOwner = false;

    uint8_t logEid = getDebugEid();

    if (!ec)
    {
        int fd = mctpSocket->native_handle();

        /// @brief Peek message length
        len = recvfrom(fd, nullptr, 0, MSG_PEEK | MSG_TRUNC, nullptr, nullptr);

        if (len < MINIMUM_LENGTH)
        {
            mctpPrErr("%s: The Recevied Packet length is invalid ", __func__);
            goto cleanup;
        }

        if (len == 0)
        {
            mctpPrErr("%s: Packet length is zero, skipping malloc", __func__);
            goto cleanup;
        }

        rxbuf = static_cast<uint8_t*>(malloc(len));
        if (!rxbuf)
        {
            mctpPrErr("%s: malloc failed ", __func__);
            goto cleanup;
        }

        /// @brief Receive the actual message
        recvLen = recvfrom(fd, rxbuf, len, MSG_TRUNC,
                           (struct sockaddr*)&srcAddr, &srcAddrLen);

        if (recvLen <= 0)
        {
            mctpPrErr("recvfrom  failed");
            goto cleanup;
        }

        /// mctp packet trace if debugEid is not set or matches destEid
        if (!isEidValid(logEid) ||
            (isEidValid(logEid) &&
             (srcAddr.smctp_base.smctp_addr.s_addr == logEid)))
        {
            debugEnabled = true;
        }

#ifdef CLIENT_SOCKET_INTERFACE
        // if message type is not mctp control, forward to client
        if (srcAddr.smctp_base.smctp_type != MCTP_TYPE_CONTROL)
        {
            int rc;
            rc = sendClientMsg(srcAddr.smctp_base.smctp_addr.s_addr, rxbuf,
                               recvLen, srcAddr.smctp_base.smctp_type);
            if (rc < 0)
            {
                mctpPrErr("%s: sendClientMsg failed ", __func__);
            }
            goto cleanup;
        }
#endif

        cmdCode = rxbuf[CMD_INDEX];
        mctpPrDebug("Received MCTP Command 0x%02X from Src EID: 0x%02X ",
                    cmdCode, srcAddr.smctp_base.smctp_addr.s_addr);

        if (debugEnabled)
            mctpTraceRx(rxbuf, recvLen);

        switch (cmdCode)
        {
            case MCTP_CMD_DIS_NOTIFY:
            {
                if (recvLen != sizeof(mctpCtrlCmdDiscoveryNotify))
                {
                    mctpPrErr(
                        "%s: Received Request packet was too short for MCTP_CMD_DIS_NOTIFY,",
                        __func__);
                    goto cleanup;
                }

                /// @brief Handle discovery notify (ignored for now)
                struct mctpCtrlRespDiscoveryNotify resp;
                mctpFillRespHdr(resp.ctrlHdr, rxbuf[0] & ~0x80,
                                MCTP_CMD_DIS_NOTIFY);
                resp.completionCode = MCTP_CTRL_CC_SUCCESS;
                memcpy(buffer, &resp, sizeof(mctpCtrlRespDiscoveryNotify));
                len = sizeof(mctpCtrlRespDiscoveryNotify);
                initialDiscoveryDone = true;
                break;
            }
            case MCTP_CMD_GET_EID:
            {
                if (recvLen != sizeof(mctpCtrlCmdGetEid))
                {
                    mctpPrErr(
                        "%s: Received Request packet was too short for MCTP_CMD_GET_EID,",
                        __func__);

                    goto cleanup;
                }

                /// @brief Handle get EID message
                struct mctpCtrlRespGetEid resp;
                mctpFillRespHdr(resp.ctrlHdr, rxbuf[0] & ~0x80,
                                MCTP_CMD_GET_EID);
                resp.completionCode = MCTP_CTRL_CC_SUCCESS;

                for (auto& device : deviceRegistry.devices)
                {
                    if (device.eid == srcAddr.smctp_base.smctp_addr.s_addr)
                    {
                        resp.eid = device.localEid;
                    }
                }

                if (mode == MCTP_INTEL_I3C_BRIDGE)
                {
                    resp.eidType = 0x010; // eid type
                }

                for (auto& device : deviceRegistry.devices)
                {
                    if (device.eid == srcAddr.smctp_base.smctp_addr.s_addr)
                    {
                        if (device.isSecondaryBusOwner)
                        {
                            resp.eidType =
                                0x00; // eid type for secondary bus owner
                        }
                        break;
                    }
                }

                memcpy(buffer, &resp, sizeof(mctpCtrlRespGetEid));
                len = sizeof(mctpCtrlRespGetEid);
                break;
            }
            case MCTP_CMD_SET_EID:
            {
                /// @brief Validate the received packet length for
                /// MCTP_CMD_SET_EID
                if (recvLen != sizeof(mctpCtrlCmdSetEid))
                {
                    mctpPrErr(
                        "%s: Received Request packet was too short for MCTP_CMD_SET_EID,",
                        __func__);
                    goto cleanup;
                }
                /// @brief Handle set EID message
                uint8_t reqSetEid = rxbuf[3]; // EID from set EID request
                struct mctpCtrlRespSetEid resp;
                resp.ctrlHdr.rqDgramInst = rxbuf[0] & ~0x80; // Instance ID
                resp.ctrlHdr.commandCode = MCTP_CMD_SET_EID; // Command code
                resp.completionCode = MCTP_CTRL_CC_SUCCESS;  // Completion code
                resp.status =
                    MCTP_SETEID_ALLOC_STATUS_EID_POOL_REQ;   // Requires pool
                                                             // allocation
                resp.eidSet = rxbuf[3];                      // EID assigned
                resp.eidPoolSize = 0x02;                     // EID pool size

                for (auto& device : deviceRegistry.devices)
                {
                    if (device.eid == srcAddr.smctp_base.smctp_addr.s_addr)
                    {
                        fromSecondaryBusOwner = device.isSecondaryBusOwner;
                        if (fromSecondaryBusOwner)
                            mctpPrDebug("sete eid fromSecondaryBusOwner");

                        if (isEidValid(device.localEid) &&
                            !isLocalEidExclude(device.localEid, device.eid))
                        {
                            mctpPrInfo(
                                "set eid cmd received, Deleting old local EID:0x%02X for ifIndex :%d",
                                device.localEid, device.ifIndex);

                            ret = mctpAddrDel(device.localEid, device.ifIndex);
                            if (ret < 0)
                            {
                                mctpPrErr(
                                    "%s: deleting primary local EID addr failed",
                                    __func__);
                                // goto cleanup;
                            }
                        }

                        ret = addAddr(reqSetEid, device.ifIndex);
                        if (ret < 0)
                        {
                            mctpPrErr("%s: adding local EID addr failed",
                                      __func__);
                            goto cleanup;
                        }

                        device.localEid = reqSetEid;
                        mctpPrInfo("Set Local EID:0x%02X for ifIndex :%d",
                                   device.localEid, device.ifIndex);

                        if (mode == MCTP_INTEL_I3C_BRIDGE)
                        {
                            if (AddPidMapping(device.localEid, device.hwAddr) <
                                0)
                            {
                                mctpPrErr(
                                    "adding primary local eid map failed");
                            }
                        }
                        break;
                    }
                }

                if (fromSecondaryBusOwner)
                {
                    mctpPrDebug("secondary_eid_assigned now \n");
                    resp.status =
                        MCTP_SETEID_ALLOC_STATUS_EID_POOL_NOT_REQ; // Pool
                                                                   // allocation
                                                                   // not
                                                                   // required
                    resp.eidPoolSize = 0x00; // EID pool size
                }

                memcpy(buffer, &resp, sizeof(mctpCtrlRespSetEid));
                len = sizeof(mctpCtrlRespSetEid);
                // displayPidMappings();
                break;
            }
            /// @brief Handle get UUID command
            case MCTP_GET_EP_UUID:
            {
                if (recvLen != sizeof(mctpCtrlCmdGetUuid))
                {
                    mctpPrErr(
                        "%s: Received Request packet was too short for MCTP_GET_EP_UUID,",
                        __func__);
                    goto cleanup;
                }
                /// @brief Handle get UUID
                struct mctpCtrlRespGetUuid resp;
                mctpFillRespHdr(resp.ctrlHdr, rxbuf[0] & ~0x80,
                                MCTP_GET_EP_UUID);
                resp.completionCode = MCTP_CTRL_CC_SUCCESS;

                memcpy(&resp.uuid, &ownUuid, 16);
                memcpy(buffer, &resp, sizeof(mctpCtrlRespGetUuid));
                len = sizeof(mctpCtrlRespGetUuid);
                break;
            }

            /// @brief Handle get message type command
            case MCTP_GET_MSG_TYPE:
            {
                if (recvLen != sizeof(mctpCtrlCmdGetMsgTypeSupport))
                {
                    mctpPrErr(
                        "%s: Received Request packet was too short for MCTP_GET_MSG_TYPE,",
                        __func__);
                    goto cleanup;
                }
                /// @brief Handle get message type
                struct mctpCtrlRespGetMsgTypeSupport resp;
                mctpFillRespHdr(resp.ctrlHdr, rxbuf[0] & ~0x80,
                                MCTP_GET_MSG_TYPE);
                resp.completionCode = MCTP_CTRL_CC_SUCCESS;

                resp.msgTypeCount = 0x01;      // Number of types supported
                resp.msgTypesSupported = 0x05; // VDM type
                memcpy(buffer, &resp, sizeof(mctpCtrlRespGetMsgTypeSupport));
                len = sizeof(mctpCtrlRespGetMsgTypeSupport);
                break;
            }

            /// @brief Handle get vendor message type command
            case MCTP_CMD_GET_VENDOR_MESSAGE_SUPPORT:
            {
                if (recvLen != sizeof(mctpCtrlCmdGetVdmSupport))
                {
                    mctpPrErr(
                        "%s: Received Request packet was too short for MCTP_CMD_GET_VENDOR_MESSAGE_SUPPORT,",
                        __func__);
                    goto cleanup;
                }
                /// @brief Handle get vendor message type
                struct mctpCtrlRespGetMsgTypeSupport resp;
                mctpFillRespHdr(resp.ctrlHdr, rxbuf[0] & ~0x80,
                                MCTP_CMD_GET_VENDOR_MESSAGE_SUPPORT);
                resp.completionCode = MCTP_CTRL_CC_SUCCESS;

                memcpy(buffer, &resp, 3);
                len = 3;
                break;
            }

            /// @brief Handle allocate EID pool message
            case MCTP_CMD_ALLOC_POOL_ID:
            {
                if (recvLen != sizeof(mctpCtrlCmdAllocEid))
                {
                    mctpPrErr(
                        "%s: Received Request packet was too short for MCTP_CMD_ALLOC_POOL_ID,",
                        __func__);
                    goto cleanup;
                }
                /// @brief Handle allocate EID pool message
                eidPoolStartEid = rxbuf[4];
                PstartEid = eidPoolStartEid;
                eidPoolsize = rxbuf[3];
                eidPoolAssigned = true;
                mctpPrInfo("EID pool assigned: 0x%02X", eidPoolStartEid);

                struct mctpCtrlRespAllocEid resp;
                resp.ctrlHdr.rqDgramInst = rxbuf[0] & ~(0x80); // Instance ID
                resp.ctrlHdr.commandCode =
                    MCTP_CMD_ALLOC_POOL_ID;                    // Command code
                resp.completionCode = MCTP_CTRL_CC_SUCCESS; // Completion code
                resp.allocStatus =
                    MCTP_ALLOC_EID_ACCEPTED; // Allocation accepted
                resp.eidPoolSize = rxbuf[3]; // EID pool size
                resp.eidStart = rxbuf[4];    // Starting EID
                memcpy(buffer, &resp, sizeof(mctpCtrlRespAllocEid));
                len = sizeof(mctpCtrlRespAllocEid);
                break;
            }

            /// @brief Handle routing info update command
            case MCTP_ROUTING_INFO_UPDATE:
            {
                if (recvLen <= 0)
                {
                    mctpPrErr(
                        "%s: Received Request packet was too short for MCTP_ROUTING_INFO_UPDATE ",
                        __func__);
                    goto cleanup;
                }

                /// @brief Handle routing info update
                struct mctpCtrlRespAllocEid resp;
                resp.ctrlHdr.rqDgramInst = rxbuf[0] & ~(0x80); // Instance ID
                resp.ctrlHdr.commandCode =
                    MCTP_ROUTING_INFO_UPDATE;                  // Command code
                resp.completionCode = MCTP_CTRL_CC_SUCCESS; // Completion code
                memcpy(buffer, &resp, sizeof(mctpCtrlRespRoutingUpdate));
                len = sizeof(mctpCtrlRespRoutingUpdate);
                break;
            }

            /// @brief Handle get routing table command
            case MCTP_CMD_GET_ROUTING_TABLE:
            {
                [[maybe_unused]] uint8_t busOwnerEid = 0;
                [[maybe_unused]] uint8_t secondaryBusOwnerEid = 0;
                [[maybe_unused]] bool isSecondaryBo = false;

                if (recvLen != sizeof(mctpCtrlCmdGetRoutingTable))
                {
                    mctpPrErr(
                        "%s: Received Request packet was too short for MCTP_CMD_GET_ROUTING_TABLE",
                        __func__);
                    goto cleanup;
                }
                mctpPrDebug(
                    "MCTP_CMD_GET_ROUTING_TABLE called from EID 0x%02X ",
                    srcAddr.smctp_base.smctp_addr.s_addr);

                /// Handle routing table request
                if (!g_routing_table_entries)
                {
                    mctpPrDebug("routing table entries is null");
                    goto cleanup;
                }

                if (mode == MCTP_INTEL_I3C_BRIDGE)
                {
                    for (auto& device : deviceRegistry.devices)
                    {
                        if (device.role == "BusOwner" &&
                            !device.isSecondaryBusOwner)
                        {
                            busOwnerEid = device.eid;
                        }
                        if (device.isSecondaryBusOwner)
                        {
                            secondaryBusOwnerEid = device.eid;
                        }

                        if (device.eid == srcAddr.smctp_base.smctp_addr.s_addr)
                        {
                            if (device.isSecondaryBusOwner)
                            {
                                fromSecondaryBusOwner = true;
                            }
                        }
                    }

                    /// Ignore routing table request from PFR until received
                    /// from CPU
                    if (g_routing_table_length <= 1)
                    {
                        mctpPrDebug(
                            "routing table not received from CPU, ignore");
                        goto cleanup;
                    }
                }

                /// Prepare routing table response
                struct mctpCtrlRespGetRoutingTable resp;
                resp.ctrlHdr.rqDgramInst = rxbuf[0] & ~(0x80); // Instance ID
                resp.ctrlHdr.commandCode =
                    MCTP_CMD_GET_ROUTING_TABLE;                // Command code
                resp.completionCode = MCTP_CTRL_CC_SUCCESS; // Completion code
                resp.nextEntryHandle = 0xFF;                // No more entries
                resp.numberOfEntries = g_routing_table_length;
                memcpy(buffer, &resp, sizeof(mctpCtrlRespGetRoutingTable));

                int pos = sizeof(mctpCtrlRespGetRoutingTable);

                size_t copy_size =
                    offsetof(getRoutingTableEntry, physAddressSize);
                int entry_offset = copy_size + 2;

                if (mode == MCTP_INTEL_I3C_BRIDGE)
                {
                    /// If request comes from CPU1 or PFR
                    if (!isSecondaryBo)
                    {
                        /// Traverse the routing table
                        auto tempEntry = g_routing_table_entries;
                        while (tempEntry != NULL)
                        {
                            if (tempEntry->routeVia != secondaryBusOwnerEid)
                            {
                                /// Copy all members except physical address
                                /// size and physical address
                                memcpy(&buffer[pos], &tempEntry->routingTable,
                                       copy_size);
                                /// Set physical address size and address
                                buffer[pos + copy_size] =
                                    0x01; // Physical address size
                                buffer[pos + copy_size + 1] =
                                    0x00; // Physical address
                                pos += entry_offset;
                                entries_count++;
                            }
                            tempEntry = tempEntry->next;
                        }
                        len = 5 + ((entries_count) *
                                   (sizeof(getRoutingTableEntry) - 1));
                        buffer[ENTRY_COUNT_OFFSET] = entries_count;
                    }
                    else
                    {
                        /// If request comes from CPU2
                        auto tempEntry = g_routing_table_entries;
                        while (tempEntry != NULL)
                        {
                            if (tempEntry->routeVia != busOwnerEid)
                            {
                                /// Copy all members except physical address
                                /// size and physical address
                                memcpy(&buffer[pos], &tempEntry->routingTable,
                                       copy_size);
                                /// Set physical address size and address
                                buffer[pos + copy_size] =
                                    0x01; // Physical address size
                                buffer[pos + copy_size + 1] =
                                    0x00; // Physical address
                                pos += entry_offset;
                                entries_count++;
                            }
                            tempEntry = tempEntry->next;
                        }
                        len = 5 + ((entries_count) *
                                   (sizeof(getRoutingTableEntry) - 1));
                        buffer[ENTRY_COUNT_OFFSET] = entries_count;
                    }
                }
                else
                {
                    /// Copy entire routing table
                    auto tempEntry = g_routing_table_entries;
                    while (tempEntry != NULL)
                    {
                        memcpy(&buffer[pos], &tempEntry->routingTable,
                               sizeof(getRoutingTableEntry));
                        pos += sizeof(getRoutingTableEntry);
                        entries_count++;
                        tempEntry = tempEntry->next;
                    }
                    len = 5 + (entries_count * (sizeof(getRoutingTableEntry)));
                    buffer[ENTRY_COUNT_OFFSET] = entries_count;
                }
                break;
            }
            default:
            {
                mctpPrErr("%s: Unknown command received: %d", __func__,
                          cmdCode);
                break;
            }
        }

        /// Clear the tag-owner bit but keep the tag value for the reply
        srcAddr.smctp_base.smctp_tag &= ~MCTP_TAG_OWNER;

        /// Return message to sender
        sendLen = sendto(fd, buffer, len, 0, (struct sockaddr*)&srcAddr,
                         sizeof(srcAddr));
        if (sendLen != static_cast<ssize_t>(len))
        {
            mctpPrErr("%s: sendto failed with ret :%d", __func__, sendLen);
            mctpPrErr("%s: errno: %d, error: %s", __func__, errno,
                      strerror(errno));
            goto cleanup;
        }

        if (debugEnabled)
            mctpTraceTx(buffer, len);

        if (mode == MCTP_INTEL_I3C_BRIDGE)
        {
            if (initialDiscoveryDone && eidPoolAssigned)
            {
                mctpPrInfo(
                    "Device Discovered and EID pool Received, Setting EID");

                for (MctpDevice& device : deviceRegistry.devices)
                {
                    if (device.role == "Endpoint")
                    {
                        // Skip controller devices that were not detected during
                        // bus scanning
                        if (device.isController && !device.detected)
                        {
                            mctpPrInfo(
                                "Skipping EID assignment for undetected controller endpoint: %s",
                                device.name.c_str());
                            continue;
                        }

                        uint8_t set_eid = eidPoolStartEid;
                        /// Post timer work to io_context so device
                        /// discovery will run in background
                        if (set_eid < (PstartEid + eidPoolsize))
                        {
                            post(io, [&device, set_eid] {
                                int rc = 0;
                                if ((rc = initEndpointDiscovery(device,
                                                                set_eid)) >= 0)
                                {
                                    eidPoolAssigned = false;
                                    if (!rc)
                                    {
                                        registerRoutingTableEndpoints();
                                        eidPoolStartEid++;
                                    }
                                    else
                                    {
                                        mctpPrInfo(
                                            "%s: EID: 0x%02X is already in use by endpoint ",
                                            __func__, set_eid);
                                    }
                                }
                            });
                        }
                        else
                        {
                            mctpPrDebug(
                                "set_eid is not with in the range of eidpoolsize");
                            eidPoolAssigned = false;
                        }
                    }
                }
            }
        }

    cleanup:
        if (rxbuf)
        {
            free(rxbuf);
            rxbuf = nullptr;
        }

        /// Re-arm async read
        mctpSocket->async_wait(posix::stream_descriptor::wait_read,
                               handleMctpControlCommand);
    }
}

/// @brief Async timer (posted to queue to give I/O priority)
/// @param ec Boost system error code
void timerHandler(const boost::system::error_code& ec)
{
    auto timerInterval = std::chrono::seconds(60);
    if (!ec)
    {
        if (!skipIteration)
        {
            for (auto& device : deviceRegistry.devices)
            {
                if ((device.role == "BusOwner") && (isEidValid(device.eid)))
                {
                    // Skip controller devices that were not detected during bus
                    // scanning
                    if (device.isController && !device.detected)
                    {
                        // mctpPrInfo("Skipping routing table check for
                        // undetected controller BusOwner: %s",
                        // device.name.c_str());
                        continue;
                    }

                    /// @brief Post timer work to io_context so any ready I/O
                    /// executes first
                    post(io, [&device] {
                        int ret = getRoutingTableEntries(device);
                        if (ret < 0)
                        {
                            mctpPrErr(
                                "%s: mctp_ctrl_req_routing_table_send_recv fn call failed for cpu ",
                                __func__);
                            deleteEndpoints();
                        }
                        registerRoutingTableEndpoints();
                    });
                }
                if (device.isSecondaryBusOwner)
                {
                    // Skip controller devices that were not detected during bus
                    // scanning
                    if (device.isController && !device.detected)
                    {
                        // mctpPrInfo("Skipping secondary BusOwner notification
                        // for undetected controller: %s", device.name.c_str());
                        continue;
                    }

                    /// @brief Send only after primary bus owner detection is
                    /// done
                    if (!secondaryBusOwnerDiscoveryNotifySent)
                    {
                        auto rc = sendDiscoveryNotify(device);
                        if (rc < 0)
                            mctpPrErr(
                                "Secondary Busowner sendDiscoveryNotify failed");
                        else
                            secondaryBusOwnerDiscoveryNotifySent = true;
                    }
                }
            }
        }
        else
        {
            skipIteration = false;
            timerInterval = std::chrono::seconds(30);
        }

        /// @brief Re-arm timer
        timer->expires_after(timerInterval);
        timer->async_wait(timerHandler);
    }
}

/**
 * @brief Signal handler for termination signals.
 *
 * This function is invoked when a termination signal is received. It cleans up
 * resources and stops the I/O context to gracefully exit the service.
 *
 * @param ec Boost system error code.
 * @param signo Signal number received.
 */
void signalHandler(const boost::system::error_code& ec, int sigNum)
{
    if (!ec)
    {
        mctpPrErr("%d Signal received, exiting service", sigNum);
        deleteEndpoints();
        DeviceRegistry::closeGlobalSocket();
        cleanupDebugMonitor();
        io.stop();
    }
}

/**
 * @brief Handler for power reset events.
 *
 * This function is triggered when a power reset event is detected. It clears
 * all registered EIDs, resets the device registry, and initiates device
 * discovery.
 *
 * @param ec Boost system error code.
 */
void pwrResetHandler(const boost::system::error_code& ec)
{
    int rc;
    mctpPrInfo("PowerReset handler triggered");

    if (!ec)
    {
        skipIteration = true;
        supress = false;

        mctpPrInfo("Platform reset Detected, clearing all registered EIDs");

        // Delete endpoints and clear flags
        deleteEndpoints();
        eidPoolAssigned = false;
        secondaryBusOwnerDiscoveryNotifySent = false;

        for (auto& device : deviceRegistry.devices)
        {
            // Clear BusOwner and Endpoint EIDs in device registry
            device.eid = 0;

            // Reset controller device detection status after power reset
            if (device.isController)
            {
                device.detected = false;
                device.dynamicAddr = 0;
                mctpPrInfo("Reset detection status for controller device: %s",
                           device.name.c_str());
            }

            if (device.role == "BusOwner")
            {
                // Delete PID mappings
                deletePidMapping(device.localEid);
            }
            if (isEidValid(device.localEid))
            {
                // Delete local address assigned by BusOwner
                rc = mctpAddrDel(device.localEid, device.ifIndex);
                if (rc < 0)
                {
                    mctpPrErr("%s: deleting EID addr set by BusOwner",
                              __func__);
                }
            }
        }

/// @brief BHS Changes
#ifdef ASPEED_SOC
        /// @brief Scan I3C bus and update hardware and dynamic address
        scanI3CBuses();

        // Log detection status for all controller devices
        for (const auto& device : deviceRegistry.devices)
        {
            if (device.isController)
            {
                mctpPrInfo("Controller device %s detection status: %s",
                           device.name.c_str(),
                           device.detected ? "DETECTED" : "NOT DETECTED");
            }
        }
#else

#ifdef NUVOTON_SOC
        discoverI3cDevices();
#endif
        // For non-ASPEED SOC platforms, re-trigger device detection
        // using PID-based dynamic address lookup
        mctpPrInfo("Re-triggering device detection for non-ASPEED platform");
        for (auto& device : deviceRegistry.devices)
        {
            if (device.isController)
            {
                // Convert hwAddr (PID) to string format for lookup
                std::string pidStr = convertHwAddrToPidString(device.hwAddr);

                if (!pidStr.empty() && pidStr != "000000000000")
                {
                    try
                    {
                        std::string dynamicAddr =
                            findDynamicAddressByPID(pidStr, device);
                        if (!dynamicAddr.empty())
                        {
                            mctpPrInfo(
                                "Re-detected controller device PID: %s, Dynamic Address: %s",
                                pidStr.c_str(), dynamicAddr.c_str());
                        }
                        else
                        {
                            mctpPrInfo(
                                "Controller device PID: %s not detected after power reset",
                                pidStr.c_str());
                        }
                    }
                    catch (const std::exception& e)
                    {
                        mctpPrErr("Error re-detecting device PID %s: %s",
                                  pidStr.c_str(), e.what());
                    }
                }
            }
        }
#endif

        // Reconfigure local interfaces after power reset
        mctpSetupLocalInterfaces();

        // Initiate device discovery for Endpoint and send discovery notify
        mctpDeviceDiscoveryWorkflow();
    }
}

/**
 * @brief Callback handler for property changed signal.
 *
 * This function is invoked when a property change is detected on the power
 * state interface. It checks for the "ESpiPlatformReset" property and triggers
 * the power reset handler if necessary.
 *
 * @param m Pointer to the D-Bus message.
 * @param userdata User data (unused).
 * @param retError Pointer to the D-Bus error structure.
 * @return int Returns 0 on success.
 */
int pwrStateChangeHandler(sd_bus_message* m, void* /* userdata */,
                          sd_bus_error* retError)
{
    mctpPrInfo("pwrState Interface Properties change Detected \n");
    static int delay = 5; // Default delay of 5 seconds

    if (retError != nullptr && sd_bus_error_is_set(retError))
    {
        mctpPrErr("Got sdbus error on match \n");
        return 0;
    }
    sdbusplus::message::message message(m);
    std::string iface;
    std::map<std::string, std::variant<std::string, bool>> changedProperties;
    bool platformResetValue = false; // Initialize the actual boolean value
    message.read(iface, changedProperties);

#if defined(ASPEED_SOC) && !defined(ASPEED_2700_SOC)
    auto it = changedProperties.find("ESpiPlatformReset");

    if (it == changedProperties.end())
        return 0;

    // changedProperties is a map of property names to std::variant<std::string,
    // bool>. We expect "ESpiPlatformReset" to be a bool, so we use
    // std::get_if<bool>.
    bool* platformReset = std::get_if<bool>(&it->second);
    if (platformReset == nullptr)
    {
        mctpPrErr("Unable to read platformReset\n");
        return 0;
    }
    platformResetValue = *platformReset;
#else
    auto it = changedProperties.find("CurrentHostState");

    if (it == changedProperties.end())
        return 0;

    // changedProperties is a map of property names to std::variant<std::string,
    // bool>. We expect "CurrentHostState" to be a string, so we use
    // std::get_if<std::string>.
    std::string* currentHostState = std::get_if<std::string>(&it->second);
    if (currentHostState == nullptr)
    {
        mctpPrErr("Unable to read CurrentHostState\n");
        return 0;
    }

    // Use boost::ends_with to check if the host state ends with ".Running"
    // If it does NOT end with ".Running", then it's a platform reset condition
    bool on = boost::algorithm::ends_with(*currentHostState, ".Running");
    if (on)
        delay = 10;
    platformResetValue = true;

#endif

    if (platformResetValue && (!supress))
    {
        mctpPrInfo("PlatformReset: %d", platformResetValue);
        supress = true;
        auto pwrResetTimer = std::make_shared<boost::asio::steady_timer>(io);
        pwrResetTimer->expires_after(boost::asio::chrono::seconds(delay));
        pwrResetTimer->async_wait(
            [pwrResetTimer](const boost::system::error_code& ec) {
                pwrResetHandler(ec);
            });
    }

    return 0;
}

// Add implementations before main (or wherever appropriate above main):
int setupMctpCtrlMshHandler()
{
    /// @brief MCTP socket setup
    int fd = socket(AF_MCTP, SOCK_DGRAM, 0);
    if (fd < 0)
    {
        perror("socket");
        return -1;
    }

    sockaddr_mctp addr{};
    addr.smctp_family = AF_MCTP;
    addr.smctp_addr.s_addr = MCTP_ADDR_ANY;
    addr.smctp_network = MCTP_I3C_NET;
    addr.smctp_type = MCTP_CTRL_TYPE;
    addr.smctp_tag = MCTP_TAG_OWNER;

    if (bind(fd, (struct sockaddr*)&addr, sizeof(addr)) < 0)
    {
        perror("bind");
        close(fd);
        return -1;
    }

    int val = 1;
    if (setsockopt(fd, SOL_MCTP, MCTP_OPT_ADDR_EXT, &val, sizeof(val)) < 0)
    {
        perror("MCTP_OPT_ADDR_EXT");
        close(fd);
        return -1;
    }

    mctpSocket = std::make_unique<posix::stream_descriptor>(io, fd);
    mctpSocket->async_wait(posix::stream_descriptor::wait_read,
                           handleMctpControlCommand);

    return 0;
}

int setupMctpClinetSktHandler()
{
    mctpPrDebug("Client socket interface enabled");
    int client_sockfd;

    if (ClientSocketInit(client_sockfd) < 0)
    {
        mctpPrErr("Client socket init failed");
        close(client_sockfd);
        return -1;
    }

    clientSocket =
        std::make_unique<posix::stream_descriptor>(io, client_sockfd);
    clientSocket->async_wait(posix::stream_descriptor::wait_read,
                             [&](const boost::system::error_code& ec) {
                                 acceptHandler(ec, clientSocket);
                             });
    return 0;
}

void setupPwrResetHandler()
{
    /// @brief Timer setup
    timer = std::make_unique<steady_timer>(io);
    timer->expires_after(20s);
    timer->async_wait(timerHandler);

    /// @brief Signal setup
    signals.async_wait(signalHandler);

    static std::unique_ptr<sdbusplus::bus::match::match> powerStateMonitor;

#ifdef ASPEED_SOC
    /// @brief Register property changed signal for power state
    std::string propertiesMatchString =
        "type='signal',path='/xyz/openbmc_project/misc/platform_state',"
        "interface='org.freedesktop.DBus.Properties',"
        "member='PropertiesChanged',arg0='xyz.openbmc_project.State.Host.Misc'";
#else
    /// @brief Register property changed signal for power state
    std::string propertiesMatchString =
        "type='signal',path='/xyz/openbmc_project/state/host0',"
        "interface='org.freedesktop.DBus.Properties',"
        "member='PropertiesChanged',arg0='xyz.openbmc_project.State.Host'";
#endif

    powerStateMonitor = std::make_unique<sdbusplus::bus::match::match>(
        *conn, propertiesMatchString, pwrStateChangeHandler, nullptr);
}

/**
 * @brief Parses the JSON configuration file.
 *
 * This function reads the JSON configuration file and populates the device
 * registry with the devices specified in the configuration.
 *
 * @return bool Returns true on success, false on failure.
 */
bool parseJsonConfig()
{
    auto populate = deviceRegistry.populateDevicesFromJson(g_config_file);
    if (!populate)
    {
        mctpPrErr("Failed to populate device registry from config");
        return false;
    }

    for (auto& device : deviceRegistry.devices)
    {
        // Update index
        if (device.isController)
        {
// TODO: Fix driver bus number not matching with interface bus name
#if defined(ASPEED_SOC) && !defined(ASPEED_2700_SOC)
            // BHS changes
            device.ifIndex = getInterfaceIndex(
                ("mctpi3c" + std::to_string(device.busNumber - 2)).c_str());
#else
            device.ifIndex = getInterfaceIndex(
                ("mctpi3c" + std::to_string(device.busNumber)).c_str());
#endif
        }
        else
        {
            device.ifIndex = getInterfaceIndex(
                ("mctpi3c-target" + std::to_string(device.busNumber)).c_str());
        }

        if (device.ifIndex < 0)
        {
            mctpPrErr("Invalid interface for device: %s", device.name.c_str());
            return false;
        }

        mctpPrInfo("Device: %s, Role: %s, Bus: %d, PID Mask: 0x%hu Index:%d ",
                   device.name.c_str(), device.role.c_str(), device.busNumber,
                   device.pidMask, device.ifIndex);

#ifdef ASPEED_SOC
        if (MCTP_I3C_NET == 1)
            MCTP_I3C_NET =
                device.ifIndex; // Use first device ifindex as MCTP I3C network
#endif
    }

    // Initialize global MCTP socket for all communications
    mctpPrInfo("Initializing global MCTP socket...");
    int ret = DeviceRegistry::initializeGlobalSocket();
    if (ret < 0)
    {
        mctpPrWarn(
            "Failed to initialize global MCTP socket - will use temporary sockets");
        return false;
    }
    else
    {
        mctpPrInfo("Global MCTP socket initialized successfully");
    }

    return true;
}

/**
 * @brief Handles command-line arguments.
 *
 * This function parses the command-line arguments and sets the global
 * configuration variables accordingly.
 *
 * @param argc Argument count.
 * @param argv Argument vector.
 */
void parseArgs(int argc, char* argv[])
{
    int opt;
    while ((opt = getopt(argc, argv, "c:m:p:")) != -1)
    {
        switch (opt)
        {
            case 'c':
                g_config_file = optarg;
                break;
            case 'm':
                mode = atoi(optarg);
                break;
            case 'p':
                startEid = atoi(optarg);
                break;
            default:
                fprintf(stderr, "Usage: %s [-v] -c <config.json>\n", argv[0]);
                exit(EXIT_FAILURE);
        }
    }

    if (g_config_file.empty())
    {
        fprintf(stderr, "Error: Config file must be specified with -c\n");
        fprintf(stderr,
                "Usage: %s -c <config.json> [-m <mode>] [-p <pool_eid>]\n",
                argv[0]);
        exit(EXIT_FAILURE);
    }
}

/// @brief Main entry point for the MCTP I3C Application.
/// @param argc Argument count.
/// @param argv Argument vector.
/// @return int Returns 0 on success, or a negative error code on failure.
int main(int argc, char* argv[])
{
    /// @brief Enable MCTP traces
    mctpSetLogStdio(MCTP_LOG_TRACE);
    mctpSetTracingEnabled(true);

    /// @brief Parse command-line arguments
    parseArgs(argc, argv);

    /// @brief D-Bus setup (sdbusplus)
    conn = std::make_shared<sdbusplus::asio::connection>(io);
    conn->request_name(MCTP_CTRL_DBUS_NAME);
    server = std::make_unique<sdbusplus::asio::object_server>(conn);

    /// @brief Set up D-Bus event processing during device scanning
    setProcessEventsCallback([&]() {
        io.poll(); // Process D-Bus events without blocking
    });

    auto iface = server->add_interface("/xyz/openbmc_project/mctp",
                                       "xyz.openbmc_project.MCTP.Responder");
    iface->register_property("Version", std::string{"1.0"});
    iface->initialize();

    server->add_manager("/xyz/openbmc_project/mctp");

    /// @brief Populate device registry based on JSON configuration
    if (!parseJsonConfig())
    {
        mctpPrErr("Failed to parse json configuration exiting ");
        return -1;
    }

#ifdef ASPEED_SOC
    /// @brief Scan I3C bus and update hardware and dynamic address
    scanI3CBuses();

#else

#ifdef NUVOTON_SOC
    discoverI3cDevices();
#endif
    /// @brief Update dynamic addresses using findDynamicAddressByPID
    mctpPrInfo("Updating device dynamic addresses using PID lookup...");
    for (auto& device : deviceRegistry.devices)
    {
        // Only lookup dynamic address if it's not already set
        if (device.dynamicAddr == 0)
        {
            // Convert hwAddr (PID) to string format for lookup
            std::string pidStr = convertHwAddrToPidString(device.hwAddr);

            if (!pidStr.empty() && pidStr != "000000000000")
            {
                mctpPrDebug(
                    "Looking up dynamic address for device %s with PID: %s",
                    device.name.c_str(), pidStr.c_str());

                std::string dynAddrStr =
                    findDynamicAddressByPID(pidStr, device);
                if (!dynAddrStr.empty())
                {
                    try
                    {
                        device.dynamicAddr = static_cast<uint8_t>(
                            std::stoull(dynAddrStr, nullptr, 16));
                        mctpPrInfo(
                            "Updated dynamic address for device %s: 0x%02x",
                            device.name.c_str(), device.dynamicAddr);
                    }
                    catch (const std::exception& e)
                    {
                        mctpPrErr(
                            "Failed to parse dynamic address for device %s: %s",
                            device.name.c_str(), e.what());
                        // Don't mark as detected if we can't parse the address
                        device.detected = false;
                    }
                }
                else
                {
                    mctpPrDebug(
                        "No dynamic address found for device %s with PID: %s",
                        device.name.c_str(), pidStr.c_str());
                }
            }
        }
        else
        {
            mctpPrDebug(
                "Device %s already has dynamic address: 0x%02x, skipping lookup",
                device.name.c_str(), device.dynamicAddr);
        }
    }
#endif
    for (auto& device : deviceRegistry.devices)
    {
        mctpPrDebug("Device: %s", device.name.c_str());
        printHwAddr(&device);
    }

    /// @brief Bring up interfaces and initialize addresses
    mctpSetupLocalInterfaces();

    /// @brief Initiate device discovery
    mctpDeviceDiscoveryWorkflow();

    /// @brief Disable Trcing After discovery
    mctpSetLogStdio(MCTP_LOG_WARNING);

    /// @brief Setup MCTP control message handler
    if (setupMctpCtrlMshHandler() != 0)
    {
        return 1;
    }

#ifdef CLIENT_SOCKET_INTERFACE
    if (setupMctpClinetSktHandler() != 0)
    {
        return 1;
    }
#endif

    /// @brief Setup power reset handler
    setupPwrResetHandler();

    /// @brief Initialize debug file monitoring
    if (initDebugMonitor(io) < 0)
    {
        mctpPrWarn("Failed to initialize debug file monitor");
    }
    /// @brief Run io context
    io.run();

    // Cleanup
    cleanupDebugMonitor();

    return 0;
}
