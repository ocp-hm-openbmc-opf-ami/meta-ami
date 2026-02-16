#ifndef __UTILS_H__
#define __UTILS_H__

#include "MctpDevice.hpp"
#include "mctp-app-log.hpp"
#include "mctp-netlink.hpp"

#include <dirent.h>
#include <fcntl.h>
#include <poll.h>
#include <string.h>
#include <sys/ioctl.h>
#include <unistd.h>

#include <filesystem>
#include <functional>
#include <unordered_map>
#include <unordered_set>

#define CMD_INDEX 1
#define ENDPOINT_TYPE_OFFSET 2
#define STATUS_INDEX 2
#define MINIMUM_LENGTH 2
#define MIN_RESP_LENGTH 2
#define MCTP_EID_BROADCAST 0xFF

#define MCTP_CTRL_CC_ERROR 0x01

#define MCTP_CONTROL_MSG_STATUS_ERROR_NOT_READY 0x04

#define CMD_INDEX 1
#define DEFAULT_NET 1
#define MCTP_CTRL_TYPE 0x00

typedef __u8 mctp_eid_t;

/* Various commandline modes */
typedef enum mctp_mode_ops
{
    MCTP_ENDPOINT,
    MCTP_BUSOWNER,
    MCTP_INTEL_I3C_BRIDGE,
    MCTP_BRIDGE,
} mctp_mode_ops_t;

// Global callback function pointer for processing D-Bus events
extern std::function<void()> processEventsCallback;

int configureLocalEid(uint8_t eid, int index, int net);
int getInterfaceIndex(const char* iface_name);
int pollWithTimeout(int fd, int timeout_ms);

int getPid(MctpDevice& device);
bool isEidValid(uint8_t eid);
std::string convertHwAddrToPidString(const uint8_t hwAddr[6]);
const char* phyTransportBindingToString(uint8_t id);
void scanI3CBuses();
void printHwAddr(MctpDevice* device);

void discoverI3cDevices();

int AddPidMapping(mctp_eid_t eid, const void* pid);
int deletePidMapping(mctp_eid_t eid);

std::string readDynamicAddress(const std::filesystem::path& path);
std::string findDynamicAddressByPID(const std::string& pid, MctpDevice& device);

void setProcessEventsCallback(std::function<void()> callback);

uint8_t getDebugEid();
void setDebugEid(uint8_t val);

#endif /* __UTILS_H__ */
