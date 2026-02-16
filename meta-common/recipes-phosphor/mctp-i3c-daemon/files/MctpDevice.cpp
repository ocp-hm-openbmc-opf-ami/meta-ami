#include "MctpDevice.hpp"

#include <json-c/json.h>
#include <linux/mctp.h>
#include <sys/socket.h>
#include <unistd.h>

#include <cstring>

// Define the static members
std::vector<MctpDevice> DeviceRegistry::devices;
int DeviceRegistry::globalSocketFd = -1;

// External declaration for MCTP_I3C_NET
extern int MCTP_I3C_NET;

MctpDevice::MctpDevice(int bus, std::string& devName, uint16_t pidMask,
                       std::string& devRole, bool isController,
                       bool isSecondary, uint8_t staticEid,
                       const uint8_t pid[PID_SIZE]) :
    busNumber(bus), name(std::move(devName)), pidMask(pidMask),
    role(std::move(devRole)), isController(isController),
    isSecondaryBusOwner(isSecondary), staticEid(staticEid)
{
    // Initialize hwAddr to zeros
    memset(this->hwAddr, 0, sizeof(this->hwAddr));

    if (pid != nullptr)
    {
        for (size_t i = 0; i < PID_SIZE; i++)
        {
            this->hwAddr[i] = pid[i];
        }
    }
}

/**
 * @brief Parses a hex PID string into a vector of bytes.
 * @param pidHex The PID string in hexadecimal format (with or without 0x
 * prefix).
 * @param arr Reference to vector that will be populated with parsed bytes
 * @param hwAddrLen Expected number of bytes to parse
 * @return true if parsing is successful, false otherwise.
 */
bool parsePidHexString(std::string pidHex, std::vector<uint8_t>& arr,
                       size_t hwAddrLen)
{
    if (pidHex.empty())
    {
        mctpPrErr("Error: PID string is empty");
        return false;
    }

    // parse hex prefix, if any
    if (pidHex.rfind("0x", 0) == 0 || pidHex.rfind("0X", 0) == 0)
    {
        pidHex = pidHex.substr(2);
    }

    // Pad to even length
    if (pidHex.size() % 2 != 0)
    {
        pidHex = "0" + pidHex;
    }

    if (pidHex.size() != (hwAddrLen * 2))
    {
        mctpPrErr(
            "Error: PID length must be exactly %zu hex characters (%zu bytes) in JSON file",
            hwAddrLen * 2, hwAddrLen);
        return false;
    }

    // Clear and resize vector to ensure correct size
    arr.clear();
    arr.reserve(hwAddrLen);

    for (size_t i = 0; i < hwAddrLen * 2; i += 2)
    {
        std::string byteStr = pidHex.substr(i, 2);
        try
        {
            uint8_t byte =
                static_cast<uint8_t>(std::stoul(byteStr, nullptr, 16));
            arr.push_back(byte);
        }
        catch (const std::exception& e)
        {
            mctpPrErr("Error: Invalid hex character in PID string: %s",
                      byteStr.c_str());
            return false;
        }
    }

    return true;
}

bool DeviceRegistry::populateDevicesFromJson(const std::string& fileName)
{
    const std::string filePath = "/usr/share/mctp/" + fileName;
    // const std::string filePath = "/home/root/" + fileName;
    json_object* root = nullptr;

    try
    {
        root = json_object_from_file(filePath.c_str());
        if (!root)
        {
            mctpPrErr("Failed to open or parse JSON file: %s ",
                      filePath.c_str());
            return false;
        }

        if (!json_object_is_type(root, json_type_array))
        {
            mctpPrErr("JSON root is not an array in JSON file: %s ",
                      filePath.c_str());
            json_object_put(root);
            return false;
        }

        size_t arrLen = json_object_array_length(root);
        std::vector<uint8_t> hwAddr;

        for (size_t i = 0; i < arrLen; ++i)
        {
            json_object* item = json_object_array_get_idx(root, i);
            if (!item)
                continue;

            json_object* obj = nullptr;

            int bus = 0;
            if (json_object_object_get_ex(item, "bus_number", &obj))
                bus = json_object_get_int(obj);

            std::string name;
            if (json_object_object_get_ex(item, "name", &obj))
                name = json_object_get_string(obj);

            std::string pidMaskStr;
            if (json_object_object_get_ex(item, "pidmask", &obj))
                pidMaskStr = json_object_get_string(obj);

            std::string role;
            if (json_object_object_get_ex(item, "role", &obj))
                role = json_object_get_string(obj);

            std::string pid;
            if (json_object_object_get_ex(item, "pid", &obj))
                pid = json_object_get_string(obj);

            bool isController = false;
            if (json_object_object_get_ex(item, "mctpi3c-controller", &obj))
                isController = json_object_get_boolean(obj);

            bool isSecondaryBo = false;
            if (json_object_object_get_ex(item, "secondary-bus-owner", &obj))
                isSecondaryBo = json_object_get_boolean(obj);

            uint8_t staticEid = 0;
            if (json_object_object_get_ex(item, "static-endpoint", &obj))
                staticEid = static_cast<uint8_t>(json_object_get_int(obj));

            uint32_t pidMask = 0;
            if (!pidMaskStr.empty())
            {
                pidMask =
                    static_cast<uint32_t>(std::stoul(pidMaskStr, nullptr, 16));
            }

            if (!pid.empty())
            {
                if (!parsePidHexString(pid, hwAddr, PID_SIZE))
                {
                    mctpPrErr("Error: Invalid PID format in JSON file: %s ",
                              fileName.c_str());
                    json_object_put(root);
                    return false;
                }

                // Validate vector size before passing to constructor
                if (hwAddr.size() != PID_SIZE)
                {
                    mctpPrErr(
                        "Error: PID parsing resulted in incorrect size (%zu bytes, expected %zu) in JSON file: %s",
                        hwAddr.size(), PID_SIZE, fileName.c_str());
                    json_object_put(root);
                    return false;
                }

                devices.emplace_back(bus, name, pidMask, role, isController,
                                     isSecondaryBo, staticEid, hwAddr.data());
            }
            else
            {
                devices.emplace_back(bus, name, pidMask, role, isController,
                                     isSecondaryBo, staticEid, nullptr);
            }
        }

        json_object_put(root); // free JSON object
        return true;
    }
    catch (const std::exception& e)
    {
        mctpPrErr("Exception occurred while parsing JSON file: %s, Error: %s",
                  filePath.c_str(), e.what());
        if (root)
        {
            json_object_put(root);
        }
        return false;
    }
    catch (...)
    {
        mctpPrErr("Unknown exception occurred while parsing JSON file: %s",
                  filePath.c_str());
        if (root)
        {
            json_object_put(root);
        }
        return false;
    }
}

MctpDevice* DeviceRegistry::findByEid(uint8_t eid)
{
    for (auto& dev : devices)
    {
        if (dev.eid == eid)
            return &dev;
    }
    return nullptr;
}

std::vector<MctpDevice>& DeviceRegistry::getDevices()
{
    return devices;
}

int DeviceRegistry::initializeGlobalSocket()
{
    if (globalSocketFd >= 0)
    {
        // Socket already initialized
        return 0;
    }

    globalSocketFd = socket(AF_MCTP, SOCK_DGRAM, 0);
    if (globalSocketFd < 0)
    {
        mctpPrErr("%s: Failed to create global MCTP socket", __func__);
        return -1;
    }

    // Enable extended addressing for the global socket
    int val = 1;
    int rc = setsockopt(globalSocketFd, SOL_MCTP, MCTP_OPT_ADDR_EXT, &val,
                        sizeof(val));
    if (rc < 0)
    {
        mctpPrErr("%s: Failed to enable extended addressing on global socket",
                  __func__);
        close(globalSocketFd);
        globalSocketFd = -1;
        return -1;
    }

    // mctpPrInfo("Initialized global MCTP socket: fd=%d with extended
    // addressing", globalSocketFd);
    return 0;
}

void DeviceRegistry::closeGlobalSocket()
{
    if (globalSocketFd >= 0)
    {
        close(globalSocketFd);
        globalSocketFd = -1;
    }
}

int DeviceRegistry::getGlobalSocket()
{
    if (globalSocketFd < 0)
    {
        // Try to initialize if not already done
        if (initializeGlobalSocket() < 0)
        {
            return -1;
        }
    }
    return globalSocketFd;
}
