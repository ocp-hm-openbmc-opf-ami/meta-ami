#ifndef __MCTP_CTRL__CMDS_H__
#define __MCTP_CTRL__CMDS_H__

#include "MctpDevice.hpp"
#include "mctp-app-log.hpp"
#include "mctp-encode.hpp"

#include <fcntl.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#include <sdbusplus/asio/connection.hpp>
#include <sdbusplus/asio/object_server.hpp>

// clang-format off
#include <linux/mctp.h>
// clang-format on

#define MCTP_CTRL_DBUS_NAME "xyz.openbmc_project.MCTP.Control.I3C"
#define MCTP_CTRL_DBUS_EP_INTERFACE "xyz.openbmc_project.MCTP.Endpoint"
#define MCTP_CTRL_DBUS_UUID_INTERFACE "xyz.openbmc_project.Common.UUID"
#define MCTP_CTRL_DBUS_SOCK_INTERFACE "xyz.openbmc_project.Common.UnixSocket"
#define MCTP_CTRL_SDBUS_NAME_SIZE 255
#define MCTP_MSG_TYPE_DATA_LEN_OFFSET 0
#define MCTP_MSG_TYPE_DATA_OFFSET 1
#define MCTP_CTRL_DBUS_BINDING_INTERFACE "xyz.openbmc_project.MCTP.Binding"
#define MCTP_CTRL_DBUS_DECORATOR_INTERFACE                                     \
    "xyz.openbmc_project.Inventory.Decorator.I3CDevice"
#define MCTP_CTRL_DBUS_VDM_INTERFACE "xyz.openbmc_project.MCTP.PCIVendorDefined"
#define I3C_PHY_Medium 0x30
#define I3C_PHY_BINDING 0x06
#define VENDOR_BINDING 0xFF

/* For Set Endpoint ID response param validation (as per DSP0236 Version 1.3.1)
 */
#define MCTP_SETEID_ALLOC_STATUS_EID_POOL_NOT_REQ 0
#define MCTP_SETEID_ALLOC_STATUS_EID_POOL_REQ 1

#define MCTP_SETEID_ALLOC_STATUS_EID_POOL_ASSIGNED 2
#define MCTP_SETEID_ALLOC_STATUS_EID_POOL_RESVD 3

#define MCTP_SETEID_ASSIGN_STATUS_ACCEPTED 0
#define MCTP_SETEID_ASSIGN_STATUS_REJECTED (1 << 4)
#define MCTP_SETEID_ASSIGN_STATUS_RESVD (2 << 4)
#define MCTP_SETEID_ASSIGN_STATUS_RESVD1 (3 << 4)

#define MCTP_GETEID_ENDPOINT_TYPE_MASK 0x30
#define MCTP_GETEID_ENDPOINT_TYPE_BUSOWNER_BRIDGE 0x01

/* For Allocate Endpoint IDs response param validation (as per DSP0236
 * Version 1.3.1) */
#define MCTP_ALLOC_EID_ACCEPTED 0
#define MCTP_ALLOC_EID_REJECTED 1

#define MINIMUM_LENGTH 2

enum ValidateRoutingResult
{
    ROUTE_VALID = 0,
    ROUTE_SKIP = 2,
};

bool isLocalEidExclude(uint8_t eid, uint8_t exclude_eid);
int addAddr(uint8_t eid, int ifIndex);
int sendDiscoveryNotify(MctpDevice& device);
int getMctpVersion(MctpDevice& device);
int getEid(MctpDevice& device, uint8_t eid);
int setEid(MctpDevice& device, uint8_t eid);
int getMsgType(MctpDevice& device);
int getVdmSupport(MctpDevice& device);
int getRoutingTableEntries(MctpDevice& device);
int getMsgTypesForEid(uint8_t eid);
int getVdmTypesForEid(uint8_t eid);
int getUuidForEid(uint8_t eid);
int registerRoutingTableEndpoints();
bool routingTableContainsEid(uint8_t eid);
int mctpRoutingEntryAdd(struct getRoutingTableEntry* routing_table_entry,
                        MctpDevice& device);
void deleteEndpoints();
int addRoute(uint8_t eid, const uint8_t* lladdr, int ifIndex);

#endif /* __MCTP_CTRL__CMDS_H__ */
