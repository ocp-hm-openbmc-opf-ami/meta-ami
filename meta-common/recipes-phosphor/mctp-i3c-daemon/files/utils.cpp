#include "utils.hpp"

#include <net/if.h>

#include <functional>

namespace fs = std::filesystem;

#define MAX_PID_MAP_ENTRIES 64
#define PID_SIZE 6

std::string i3cDevPath;

// Global callback function pointer for processing D-Bus events
std::function<void()> processEventsCallback = nullptr;

/// @brief debug eid
static uint8_t debugEid = 0;

#ifdef ASPEED_2700_SOC
/// @brief Aspeed 2700 SOC I3C Bus Mappings
std::unordered_map<uint8_t, std::string> i3cBusMap{
    {0, "14c20000.i3c0"}, {1, "14c21000.i3c1"}, {2, "14c22000.i3c2"},
    {3, "14c23000.i3c3"}, {4, "14c24000.i3c4"}, {5, "14c25000.i3c5"},
    {6, "14c26000.i3c6"}};
#else
/// @brief Aspeed 2600 SOC I3C Bus Mappings
std::unordered_map<uint8_t, std::string> i3cBusMap{
    {0, "1e7a2000.i3c0"}, {1, "1e7a3000.i3c1"}, {2, "1e7a4000.i3c2"},
    {3, "1e7a5000.i3c3"}, {4, "1e7a6000.i3c4"}, {5, "1e7a7000.i3c5"}};
#endif

/// @brief Per MCTP specification, EIDs 0x00-0x07 are reserved; valid EIDs start
/// from 0x08.
constexpr uint8_t MCTP_EID_RANGE_START = 0x8;

struct mctp_pid_map_req
{
    mctp_eid_t eid;
    unsigned char pid[6];
};

struct mctp_pid_map_entry_user
{
    mctp_eid_t eid;
    unsigned char pid[6];
};

struct mctp_pid_map_bulk
{
    __u32 count; ///< in/out
    struct mctp_pid_map_entry_user entries[MAX_PID_MAP_ENTRIES];
};

#define SIOCMCTPSETPIDMAP _IOW('m', 1, struct mctp_pid_map_req)
#define SIOCMCTPGETPIDMAP _IOR('m', 3, struct mctp_pid_map_bulk)
#define SIOCMCTPDELPIDMAP _IOW('m', 2, mctp_eid_t)

/**
 * @brief Get the current debug EID
 * @return current debug EID
 */
uint8_t getDebugEid()
{
    return debugEid;
}

/**
 * @brief Read dynamic address from given file path
 * @param val Value to set debugEid
 */
void setDebugEid(uint8_t val)
{
    debugEid = val;
}

/**
 * @brief Read dynamic address from given file path
 * @param path File path to read dynamic address from
 * @return dynamic address on success, empty string on failure
 */
std::string readDynamicAddress(const fs::path& path)
{
    std::ifstream file(path);
    if (!file.is_open())
        return "";
    std::string address;
    file >> address;
    return address;
}

/**
 * @brief Convert hwAddr array to PID string representation
 * @param hwAddr array of 6 bytes representing the hardware address (PID)
 * @return PID string in hexadecimal format
 */
std::string convertHwAddrToPidString(const uint8_t hwAddr[6])
{
    std::string pidStr;
    for (int i = 0; i < 6; i++)
    {
        char byte[3];
        snprintf(byte, sizeof(byte), "%02x", hwAddr[i]);
        pidStr += byte;
    }
    return pidStr;
}

/**
 * @brief Normalize PID by removing leading zeros
 * @param pid Input PID string
 * @return Normalized PID string
 */
std::string normalizePID(const std::string& pid)
{
    // Remove leading zeros
    size_t firstNonZero = pid.find_first_not_of('0');
    if (firstNonZero == std::string::npos)
    {
        // All zeros case - return "0"
        return "0";
    }
    return pid.substr(firstNonZero);
}

/**
 * @brief find dynamic address based on PID and mark device as detected
 * @param pid string representation of PID
 * @param device reference to MctpDevice to mark as detected if found
 * @return dynamic address on success, empty string on failure
 */
std::string findDynamicAddressByPID(const std::string& pid, MctpDevice& device)
{
    try
    {
        std::string normalizedPID = normalizePID(pid);
        mctpPrDebug("Searching for PID: %s (normalized: %s)", pid.c_str(),
                    normalizedPID.c_str());

        const fs::path basePath("/sys/bus/i3c/devices");
        if (!fs::exists(basePath) || !fs::is_directory(basePath))
        {
            mctpPrDebug(
                "I3C devices base path not found, device discovery may not be available");
            return "";
        }

        for (const auto& entry : fs::recursive_directory_iterator(basePath))
        {
            if (!fs::is_directory(entry))
                continue;

            const std::string dirName = entry.path().filename().string();

            // skip: check if normalized PID substring exists in folder
            // name
            if (dirName.find(normalizedPID) == std::string::npos)
                continue;

            // PID is usually after the dash, e.g., 1-20a012900ef
            auto dashPos = dirName.find('-');
            if (dashPos != std::string::npos)
            {
                std::string entryPID = dirName.substr(dashPos + 1);
                if (entryPID == normalizedPID)
                {
                    // Found the PID, check if pid file exists and matches
                    fs::path pidFilePath = entry.path() / "pid";
                    if (fs::exists(pidFilePath))
                    {
                        std::ifstream pidFile(pidFilePath);
                        if (pidFile)
                        {
                            std::string fileContent;
                            std::getline(pidFile, fileContent);
                            pidFile.close();

                            // Verify the PID matches what's in the file
                            if (fileContent == normalizedPID)
                            {
                                // Found matching PID, now read dynamic_address
                                fs::path dynAddrPath =
                                    entry.path() / "dynamic_address";
                                if (!fs::exists(dynAddrPath))
                                {
                                    mctpPrDebug(
                                        "Dynamic address file not found for PID %s",
                                        pid.c_str());
                                    return "";
                                }

                                std::string dynAddr =
                                    readDynamicAddress(dynAddrPath);
                                if (!dynAddr.empty())
                                {
                                    // Mark device as detected since we found it
                                    device.detected = true;
                                    mctpPrInfo(
                                        "Device detected: %s (PID: %s, DynAddr: 0x%s)",
                                        device.name.c_str(), pid.c_str(),
                                        dynAddr.c_str());
                                }
                                return dynAddr;
                            }
                        }
                    }
                }
            }
        }
    }
    catch (const fs::filesystem_error& e)
    {
        mctpPrErr("Filesystem error while searching for PID %s: %s",
                  pid.c_str(), e.what());
        return "";
    }
    catch (const std::exception& e)
    {
        mctpPrErr("Error while searching for PID %s: %s", pid.c_str(),
                  e.what());
        return "";
    }
    return ""; // PID not found
}

/**
 * @brief Add PID mapping for given EID
 * @param eid Endpoint ID
 * @param pid Pointer to PID data
 * @return 0 on success, -1 on failure
 */
int AddPidMapping(mctp_eid_t eid, const void* pid)
{
    int sock;
    struct mctp_pid_map_req req;

    sock = socket(AF_MCTP, SOCK_DGRAM, 0);
    if (sock < 0)
    {
        mctpPrErr("mctp socket error");
        return -1;
    }

    req.eid = eid;
    memcpy(req.pid, pid, PID_SIZE);

    if (ioctl(sock, SIOCMCTPSETPIDMAP, &req) < 0)
    {
        // if (GlobalConfig::cpus_count > 1)
        // mctpPrErr("ioctl SIOCMCTPSETPIDMAP error");
        close(sock);
        return -1;
    }

    mctpPrDebug("Mapping added: EID %u ? PID %02x:%02x:%02x:%02x:%02x:%02x",
                req.eid, req.pid[0], req.pid[1], req.pid[2], req.pid[3],
                req.pid[4], req.pid[5]);

    close(sock);
    return 0;
}

/**
 * @brief Display all PID mappings
 * @return 0 on success, -1 on failure
 */
int displayPidMappings()
{
    struct mctp_pid_map_bulk bulk = {};
    bulk.count = MAX_PID_MAP_ENTRIES;

    int sock = socket(AF_MCTP, SOCK_DGRAM, 0);
    if (sock < 0)
    {
        mctpPrErr("mctp socket error");
        return -1;
    }

    // Ask kernel to fill in the mapping
    if (ioctl(sock, SIOCMCTPGETPIDMAP, &bulk) < 0)
    {
        mctpPrErr("ioctl SIOCMCTPGETPIDMAP error");
        close(sock);
        return -1;
    }

    mctpPrDebug("Found %u PID ? EID mappings:", bulk.count);
    for (uint32_t i = 0; i < bulk.count; ++i)
    {
        mctpPrDebug("  EID %3u ? PID %02x:%02x:%02x:%02x:%02x:%02x\n",
                    bulk.entries[i].eid, bulk.entries[i].pid[0],
                    bulk.entries[i].pid[1], bulk.entries[i].pid[2],
                    bulk.entries[i].pid[3], bulk.entries[i].pid[4],
                    bulk.entries[i].pid[5]);
    }

    close(sock);
    return 0;
}

/**
 * @brief Delete PID mapping for given EID
 * @param eid Endpoint ID to delete mapping for
 * @return 0 on success, -1 on failure
 */
int deletePidMapping(mctp_eid_t eid)
{
    int sock;

    if (!isEidValid(eid))
    {
        /// if (GlobalConfig::cpus_count > 1)
        /// mctpPrErr("eid not valid , unable to delete PID Mapping");
        return -1;
    }

    sock = socket(AF_MCTP, SOCK_DGRAM, 0);
    if (sock < 0)
    {
        mctpPrErr("mctp socket error");
        return -1;
    }

    if (ioctl(sock, SIOCMCTPDELPIDMAP, &eid) < 0)
    {
        /// if (GlobalConfig::cpus_count > 1)
        /// mctpPrErr("ioctl SIOCMCTPDELPIDMAP error");
        close(sock);
        return -1;
    }

    mctpPrDebug("Mapping deleted: EID %u", eid);

    close(sock);
    return 0;
}

/**
 * @brief Print hardware address (PID) of MCTP device
 * @param device Pointer to MctpDevice
 */
void printHwAddr(MctpDevice* device)
{
    if (!device)
        return;

    mctpPrDebugRaw("Device PID: ");
    for (size_t i = 0; i < sizeof(device->hwAddr); i++)
    {
        mctpPrDebugRaw("0x%02X ", device->hwAddr[i]);
    }
    mctpPrDebugRaw("\n");
}

/**
 * @brief Scan I3C bus for MCTP devices
 * @param busNum Bus number to scan
 * @param busDevices Vector of devices to look for on the bus
 * @return true if all devices found, false otherwise
 */
bool scanBusForDevices(int busNum, std::vector<MctpDevice*>& busDevices)
{
    int tries = 20;

    if (busDevices.empty())
    {
        mctpPrErr("No devices to scan on bus %d", busNum);
        return false;
    }

    /// Lookup bus sysfs path
    auto search = i3cBusMap.find(busNum);
    if (search == i3cBusMap.end())
    {
        mctpPrErr("Bus number %d not found in i3cBusMap", busNum);
        return false;
    }

    std::string busName = search->second;
    // std::string deviceDirPath =
    //"/sys/devices/platform/ahb/ahb:apb/ahb:apb:bus@1e7a0000/" + busName;

    std::string deviceDirPath = "/sys/bus/platform/devices/" + busName;

    std::string i3cDevPath;
    std::string rescanFilePath;

    /// Find i3c device path and rescan file
    for (const auto& entry : fs::directory_iterator(deviceDirPath))
    {
        // only search directories;
        if (!entry.is_directory())
            continue;

        auto entryPath = entry.path();
        std::string pathStr = entryPath.generic_string();

        mctpPrDebug("searching path i3c device path: %s", entryPath.c_str());

#ifdef ASPEED_2700_SOC
        if (entryPath.filename().generic_string() == busName)
        {
            i3cDevPath = pathStr;
            rescanFilePath = pathStr + "/rescan";
            mctpPrDebug("Found i3c device path for 2700 soc : %s",
                        i3cDevPath.c_str());
            mctpPrDebug("Rescan file path: %s", rescanFilePath.c_str());
            break;
        }
#else
        if (pathStr.rfind(deviceDirPath + "/i3c") != std::string::npos)
        {
            i3cDevPath = pathStr;
            rescanFilePath = pathStr + "/rescan";
            mctpPrDebug("Found i3c device path: %s", i3cDevPath.c_str());
            mctpPrDebug("Rescan file path: %s", rescanFilePath.c_str());
            break;
        }
#endif
    }

    if (rescanFilePath.empty())
    {
        mctpPrErr("Failed to find rescan file for bus %d", busNum);
        return false;
    }

    /// Track which devices we already detected
    std::unordered_set<std::string> detectedNames;

    while (tries--)
    {
        /// Trigger rescan
        int fd = open(rescanFilePath.c_str(), O_WRONLY);
        if (fd < 0)
        {
            mctpPrErr("Failed to open rescan file for bus %d", busNum);
            return false;
        }
        const char* writeData = "1";
        if (write(fd, writeData, 1) != 1)
        {
            mctpPrErr("Failed to write to rescan file for bus %d", busNum);
            close(fd);
            return false;
        }
        close(fd);

        // Process D-Bus events during the delay instead of blocking
        // Break the 1-second sleep into smaller chunks to allow event
        // processing
        for (int i = 0; i < 10; i++)
        {
            usleep(100000); // 100ms
            // Allow D-Bus events to be processed if callback is set
            if (processEventsCallback)
            {
                processEventsCallback();
            }
        }

        /// Scan sysfs entries for devices
        for (const auto& entry : fs::directory_iterator(i3cDevPath))
        {
            if (!fs::is_directory(entry))
                continue;

            std::string devPath = entry.path().generic_string();
            std::string pidPath = devPath + "/pid";
            std::string dynAddrPath = devPath + "/dynamic_address";

            if (!fs::exists(pidPath))
            {
                // mctpPrDebug("PID file not found: %s", pidPath.c_str());
                continue;
            }

            std::ifstream pidFile(pidPath);
            if (!pidFile)
            {
                // mctpPrDebug("Failed to open PID file: %s", pidPath.c_str());
                continue;
            }

            std::string pidStr;
            std::getline(pidFile, pidStr);
            pidFile.close();

            uint64_t devicePid = std::stoull(pidStr, nullptr, 16);

            /// Check if this matches any expected device on this bus
            for (auto* dev : busDevices)
            {
                if (detectedNames.count(dev->name))
                    continue; /// already found

                bool matched = false;
                mctpPrDebug(
                    "Checking device %s (PID mask: 0x%04X, hwAddr PID: 0x%02X%02X%02X%02X%02X%02X)",
                    dev->name.c_str(), dev->pidMask, dev->hwAddr[0],
                    dev->hwAddr[1], dev->hwAddr[2], dev->hwAddr[3],
                    dev->hwAddr[4], dev->hwAddr[5]);

                /// PID mask check
                if (dev->pidMask != 0)
                {
                    uint16_t instIDRsvdVal =
                        static_cast<uint16_t>((devicePid & 0xFF0F));
                    if (instIDRsvdVal == dev->pidMask)
                    {
                        matched = true;
                    }
                }

                /// Direct PID check (compare against dev->hwAddr interpreted as
                /// PID)
                if (!matched)
                {
                    uint64_t devPid = 0;
                    for (int i = 0; i < 6; i++)
                    {
                        devPid = (devPid << 8) | dev->hwAddr[i];
                    }
                    if (devicePid == devPid)
                    {
                        matched = true;
                    }
                }

                if (matched)
                {
                    std::string dynAddr = "unknown";
                    if (fs::exists(dynAddrPath))
                    {
                        std::ifstream dynAddrFile(dynAddrPath);
                        if (dynAddrFile)
                        {
                            std::getline(dynAddrFile, dynAddr);
                            /// Update dynamic address (from sysfs entry or
                            /// driver discovery)
                            dev->dynamicAddr = static_cast<uint8_t>(
                                std::stoull(dynAddr, nullptr, 16));
                        }
                    }

                    // Mark device as detected
                    dev->detected = true;
                    mctpPrDebug("Detected device: name=%s", dev->name.c_str());
                    detectedNames.insert(dev->name);
                }

                if (matched && dev->pidMask != 0)
                {
                    /// Update stored hwAddr (6-byte PID from sysfs)
                    for (int i = 0; i < 6; i++)
                    {
                        dev->hwAddr[i] = (devicePid >> (8 * (5 - i))) & 0xFF;
                    }

                    mctpPrDebug("Updated device: dynAddr=0x%x name=%s",
                                dev->dynamicAddr, dev->name.c_str());
                    printHwAddr(dev);
                }
            }
        }

        ///  Stop if all devices found
        if (detectedNames.size() == busDevices.size())
        {
            mctpPrDebug("All devices detected on bus %d", busNum);
            return true;
        }
    }

    // Report partial success instead of complete failure
    if (detectedNames.size() > 0)
    {
        mctpPrInfo("Partial success on bus %d: %zu of %zu devices detected",
                   busNum, detectedNames.size(), busDevices.size());

        // Log which devices were found and which are missing
        for (const auto* dev : busDevices)
        {
            if (detectedNames.count(dev->name))
            {
                mctpPrInfo("Found device: %s", dev->name.c_str());
            }
            else
            {
                mctpPrErr("Missing device: %s", dev->name.c_str());
            }
        }

        mctpPrInfo("Continuing with %zu available devices on bus %d",
                   detectedNames.size(), busNum);
        return true; // Accept partial success
    }

    mctpPrErr("No devices detected on bus %d", busNum);
    return false;
}

/**
 * @brief Top-level function to process all I3C controller devices
 */
void scanI3CBuses()
{
    /// Group devices per bus
    std::unordered_map<int, std::vector<MctpDevice*>> controllerBuses;

    for (auto& dev : DeviceRegistry::devices)
    {
        if (dev.isController)
        {
            controllerBuses[dev.busNumber].push_back(&dev);
        }
    }

    /// Scan each bus
    for (auto& [busNum, devList] : controllerBuses)
    {
        mctpPrDebug("Scanning bus %d for %zu devices", busNum, devList.size());
        auto scanDone = scanBusForDevices(busNum, devList);
        if (!scanDone)
        {
            mctpPrErr("Failed to detect all devices on bus %d", busNum);
            return; // Continue scanning other buses even if one fails
        }
    }
}

/**
 * @brief Triggers I3C device discovery on buses.
 */
void discoverI3cDevices()
{
    /// Group devices per bus
    std::unordered_map<int, std::vector<MctpDevice*>> controllerBuses;

    for (auto& dev : DeviceRegistry::devices)
    {
        if (dev.isController)
        {
            controllerBuses[dev.busNumber].push_back(&dev);
        }
    }

    /// Scan each bus
    for (auto& [busNum, devList] : controllerBuses)
    {
        mctpPrDebug("Scanning bus %d for %zu devices", busNum, devList.size());

        // Construct the discover file path for this bus
        std::string discoverFilePath =
            "/sys/bus/i3c/devices/i3c-" + std::to_string(busNum) + "/discover";
        if (!fs::exists(discoverFilePath))
        {
            mctpPrErr("Discover file does not exist for bus %d: %s", busNum,
                      discoverFilePath.c_str());
            continue;
        }
        int fd = open(discoverFilePath.c_str(), O_WRONLY);
        if (fd < 0)
        {
            mctpPrErr("Failed to open discover file for bus %d: %s", busNum,
                      discoverFilePath.c_str());
            continue;
        }
        const char* writeData = "1";
        if (write(fd, writeData, 1) != 1)
        {
            mctpPrErr("Failed to write to discover file for bus %d: %s", busNum,
                      discoverFilePath.c_str());
            close(fd);
            continue;
        }
        close(fd);
        sleep(1); // Wait for discovery to complete
        mctpPrInfo("Triggered I3C device discovery on bus %d", busNum);
    }
}

/**
 * @brief Convert physical transport binding ID to string representation
 * @param id The transport binding ID
 * @return String representation of the transport binding
 */
const char* phyTransportBindingToString(uint8_t id)
{
    if (id == 0x0)
    {
        /// It is defined unspecified in DSP0239 but we used for SPI type
        return "SPI";
    }
    else if (id == 0x1)
    {
        /// MCTP over SMbus
        return "SMBus";
    }
    else if (id == 0x2)
    {
        /// MCTP over PCI
        return "PCIe";
    }
    else if (id == 0x3)
    {
        /// MCTP over USB
        return "USB";
    }
    else if (id == 0x04)
    {
        /// MCTP over KCS
        return "KCS";
    }
    else if (id == 0x05)
    {
        /// MCTP over Serial
        return "Serial";
    }
    else if (id == 0x06)
    {
        /// MCTP over I3C
        return "I3C";
    }
    return "Unknown";
}

/**
 * @brief Poll with timeout on a file descriptor
 * @param fd File descriptor to poll
 * @param timeout_ms Timeout in milliseconds
 * @return 0 on success, -1 on error or timeout
 */
int pollWithTimeout(int fd, int timeout_ms)
{
    struct pollfd pfd;
    pfd.fd = fd;
    pfd.events = POLLIN;

    int rc = poll(&pfd, 1, timeout_ms);
    if (rc < 0)
    {
        return -1;
    }
    else if (rc == 0)
    {
        mctpPrErr("%s: poll timeout", __func__);
        return -1;
    }
    return 0;
}

/**
 * @brief Get interface index by interface name
 * @param iface_name Name of the network interface
 * @return Interface index on success, -1 on failure
 */
int getInterfaceIndex(const char* iface_name)
{
    int ifindex = if_nametoindex(iface_name);
    if (ifindex == 0)
    {
        perror("if_nametoindex");
        return -1;
    }
    return ifindex;
}

/**
 * @brief Configure local EID for MCTP interface
 * @param eid Endpoint ID to configure
 * @param index Interface index
 * @param net Network number
 * @return 0 on success, negative value on error
 */
int configureLocalEid(uint8_t eid, int index, int net)
{
    int ret;
    /// mctpPrDebug("%s: called with eid: 0x%x net: %d", __func__, eid, net);

    ret = mctpAddrAdd(eid, index);
    if (ret < 0)
    {
        mctpPrErr("Failed to add addr for EID 0x%x", eid);
        return ret;
    }

    ret = mctpLinkSetNet(index, net);
    if (ret < 0)
    {
        mctpPrErr("Failed to add route for EID 0x%x", eid);
        return ret;
    }

    return 0;
}

/**
 * @brief Get PID and dynamic address for an MCTP device
 * @param device Reference to MctpDevice to populate with PID and address
 * information
 * @return 0 on success, -1 on error
 */
int getPid(MctpDevice& device)
{
    std::string basePath = "/sys/bus/i3c/devices/";
    std::string busPrefix = std::to_string(device.busNumber) + "-";

    for (const auto& entry : fs::directory_iterator(basePath))
    {
        std::string fileName = entry.path().filename().string();

        /// Check if the file name starts with the bus prefix
        if (fileName.rfind(busPrefix, 0) != 0)
        {
            continue;
        }

        /// Construct the PID file path
        std::string pidFilePath = entry.path().string() + "/pid";
        if (!fs::exists(pidFilePath))
        {
            continue;
        }

        /// Open the PID file and read the value
        std::ifstream pidFile(pidFilePath);
        if (!pidFile)
        {
            mctpPrErr("Error: Could not open PID file");
            continue;
        }

        std::string pidStr;
        std::getline(pidFile, pidStr);
        pidFile.close();

        try
        {
            uint64_t devicePid = std::stoull(pidStr, nullptr, 16);
            uint16_t instIDRsvdVal =
                static_cast<uint16_t>((devicePid & 0xFF0F));

            if (instIDRsvdVal == device.pidMask)
            {
                /// Get dynamic address
                /// Construct the Dynamic address file path
                std::string addrFilePath =
                    entry.path().string() + "/dynamic_address";
                if (!fs::exists(addrFilePath))
                {
                    continue;
                }

                /// Open the Dynamic address file and read the value
                std::ifstream addrFile(addrFilePath);
                if (!addrFile)
                {
                    mctpPrErr("Error: Could not open Addr file");
                    continue;
                }

                std::string addrStr;
                std::getline(addrFile, addrStr);
                addrFile.close();

                device.dynamicAddr = std::stoull(addrStr, nullptr, 16);
                /// mctpPrDebug("Device Dynamic Addr: %x ", device.dynamicAddr);
                /// mctpPrDebugRaw("Device hwAddr: ");

                int k = 0;
                /// Format each byte in the PID
                for (int i = 5; i >= 0; --i)
                {
                    uint8_t val = ((devicePid >> (i * 8)) & 0xFF);
                    device.hwAddr[k] = val;
                    k++;
                }
            }
        }
        catch (const std::exception& e)
        {
            mctpPrErr("Error: while reading PID file");
            return -1;
        }
    }
    return 0;
}

/**
 * @brief Validate if EID is within valid range
 * @param eid Endpoint ID to validate
 * @return true if EID is valid, false otherwise
 */
bool isEidValid(uint8_t eid)
{
    if (eid < MCTP_EID_RANGE_START || eid == MCTP_EID_BROADCAST)
        return false;
    return true;
}

/**
 * @brief Set callback function for processing D-Bus events during scanning
 * @param callback Function to call for processing events
 */
void setProcessEventsCallback(std::function<void()> callback)
{
    processEventsCallback = callback;
}
