#pragma once
#include "mctp-app-log.hpp"

#include <cstdint>
#include <fstream>
#include <string>
#include <vector>

// Constants
static constexpr size_t PID_SIZE = 6;

class MctpDevice
{
  public:
    int busNumber{};
    std::string name;
    uint16_t pidMask;
    std::string role;
    bool isController{};
    bool isMctpBridge{};
    bool deviceRegistered;
    bool detected{
        false};      // Flag to track if device was detected during bus scanning
    uint8_t eid{0};  // assigned later
    int ifIndex{-1}; // kernel interface index
    uint8_t hwAddr[PID_SIZE]; // hwaddr
    uint8_t dynamicAddr{0};
    uint8_t localEid;
    bool isSecondaryBusOwner;
    uint8_t staticEid; // assigned later if static-endpoint is true

    MctpDevice(int bus, std::string& devName, uint16_t pidMask,
               std::string& devRole, bool isController, bool isSecondary,
               uint8_t staticEid, const uint8_t pid[PID_SIZE]);
};

// Registry for all devices
class DeviceRegistry
{
  public:
    DeviceRegistry() = default;

    /**
     * @brief Populate the device registry from a JSON file.
     * @param filename Path to the JSON file containing device information.
     * @return true if successful, false otherwise.
     */
    bool populateDevicesFromJson(const std::string& filename);

    /**
     * @brief Find a device by its bus number.
     * @param bus Bus number.
     * @return Pointer to the device, or nullptr if not found.
     */
    MctpDevice* findByEid(uint8_t eid);

    /**
     * @brief Get reference to the vector of all devices.
     * @return Reference to the static vector of devices.
     */
    std::vector<MctpDevice>& getDevices();

    /**
     * @brief Initialize global MCTP socket for all communications
     * @return 0 on success, -1 on failure
     */
    static int initializeGlobalSocket();

    /**
     * @brief Close global MCTP socket
     */
    static void closeGlobalSocket();

    /**
     * @brief Get global MCTP socket (creates if needed)
     * @return Socket file descriptor, or -1 on failure
     */
    static int getGlobalSocket();

    // Static vector accessible globally
    static std::vector<MctpDevice> devices;

  private:
    static int globalSocketFd;
};
