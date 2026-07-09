#pragma once

#include "async_resp.hpp"
#include "dbus_singleton.hpp"
#include "dbus_utility.hpp"
#include "error_messages.hpp"
#include "logging.hpp"
#include "utils/dbus_utils.hpp"

#include <sdbusplus/asio/property.hpp>
#include <sdbusplus/message/types.hpp>
#include <sdbusplus/unpack_properties.hpp>

#include <string>
#include <variant>
#include <vector>

namespace redfish
{

enum class StorageType
{
    raidSl7,
    hba,
    raidSl8
};

// Generic enum extraction utilities
inline auto extractEnum = [](const std::string* val) {
    return val ? val->substr(val->find_last_of('.') + 1) : "";
};

inline auto extractEnumVector =
    [](const std::vector<std::string>* inputVec) -> std::vector<std::string> {
    std::vector<std::string> result;
    if (inputVec)
    {
        for (const auto& val : *inputVec)
        {
            std::size_t pos = val.find_last_of('.');
            result.push_back(
                (pos != std::string::npos) ? val.substr(pos + 1) : val);
        }
    }
    return result;
};

/**
 * @brief Fetch topology end-device properties from D-Bus.
 *
 * This is fully parameterized by service, path, and interface so it can be
 * used by any storage backend (BRCM SL7, SL8, HBA, MSCC, etc.).
 */
inline void getTopologyEndDevice(
    const std::shared_ptr<bmcweb::AsyncResp>& asyncResp,
    const std::string& service, const std::string& path,
    const std::string& interface)
{
    crow::connections::systemBus->async_method_call(
        [asyncResp](
            const boost::system::error_code& ec2,
            const std::vector<std::pair<
                std::string,
                std::variant<std::string, uint16_t, std::vector<std::string>>>>&
                propertiesList) {
            if (ec2)
            {
                return;
            }
            for (const std::pair<std::string,
                                 std::variant<std::string, uint16_t,
                                              std::vector<std::string>>>&
                     property : propertiesList)
            {
                const std::string& propertyName = property.first;

                if ((propertyName == "Type") ||
                    (propertyName == "DevicePort") ||
                    (propertyName == "SasAddress") ||
                    (propertyName == "DeviceWWID"))
                {
                    const std::string* value =
                        std::get_if<std::string>(&property.second);

                    if (value != nullptr)
                    {
                        asyncResp->res.jsonValue["EndDevice"][propertyName] =
                            extractEnum(value);
                    }
                }
                else if (propertyName == "DeviceId")
                {
                    const uint16_t* value =
                        std::get_if<uint16_t>(&property.second);

                    if (value != nullptr)
                    {
                        asyncResp->res.jsonValue["EndDevice"][propertyName] =
                            *value;
                    }
                }
                else if (propertyName == "ProtocolRole")
                {
                    const std::vector<std::string>* value =
                        std::get_if<std::vector<std::string>>(&property.second);
                    if (value != nullptr)
                    {
                        asyncResp->res.jsonValue["EndDevice"][propertyName] =
                            extractEnumVector(value);
                    }
                }
            }
        },
        service, path, "org.freedesktop.DBus.Properties", "GetAll", interface);
}

/**
 * @brief Fetch topology phy-device properties and attached end-device.
 *
 * Fully parameterized: the same @p service is used for the phy property
 * fetch and forwarded to getTopologyEndDevice(), so no device-type
 * branching is needed.  Works for BRCM SL7, SL8, HBA, and MSCC.
 */
inline void getTopologyPhyDevice(
    const std::shared_ptr<bmcweb::AsyncResp>& asyncResp,
    const std::string& service, const std::string& path,
    const std::string& interface, const char* endDevInf)
{
    crow::connections::systemBus->async_method_call(
        [asyncResp, path, service, endDevInf](
            const boost::system::error_code& ec2,
            const std::vector<std::pair<
                std::string, std::variant<std::string, uint16_t, bool>>>&
                propertiesList) {
            if (ec2)
            {
                return;
            }

            const std::string* attachedDeviceType = nullptr;
            const uint16_t* attachedPhyId = nullptr;
            const bool* enabled = nullptr;
            const bool* isOnline = nullptr;
            const bool* isVirtualPhy = nullptr;
            const bool* phyDisabledNVMe = nullptr;
            const bool* phyDisabledSASSATA = nullptr;

            const bool success = sdbusplus::unpackPropertiesNoThrow(
                dbus_utils::UnpackErrorPrinter(), propertiesList,
                "AttachedDeviceType", attachedDeviceType, "AttachedPhyId",
                attachedPhyId, "Enabled", enabled, "IsOnline", isOnline,
                "IsVirtualPhy", isVirtualPhy, "PhyDisabledNVMe",
                phyDisabledNVMe, "PhyDisabledSASSATA", phyDisabledSASSATA);

            if (!success)
            {
                messages::internalError(asyncResp->res);
                return;
            }

            if (attachedDeviceType)
            {
                asyncResp->res.jsonValue["AttachedDeviceType"] =
                    extractEnum(attachedDeviceType);
            }

            if (attachedPhyId)
            {
                asyncResp->res.jsonValue["AttachedPhyId"] = *attachedPhyId;
            }

            auto setBool = [&asyncResp](const char* key, const bool* val) {
                if (val)
                {
                    asyncResp->res.jsonValue[key] = *val;
                }
            };
            setBool("Enabled", enabled);
            setBool("IsOnline", isOnline);
            setBool("IsVirtualPhy", isVirtualPhy);
            setBool("PhyDisabledNVMe", phyDisabledNVMe);
            setBool("PhyDisabledSASSATA", phyDisabledSASSATA);

            // If device is attached, fetch end-device topology
            if (attachedDeviceType && !attachedDeviceType->empty() &&
                extractEnum(attachedDeviceType) != "NoDevice")
            {
                crow::connections::systemBus->async_method_call(
                    [asyncResp, service,
                     endDevInf](const boost::system::error_code& ec,
                                const std::vector<std::string>& topologyList) {
                        if (ec)
                        {
                            BMCWEB_LOG_ERROR("Topology mapper call error");
                            return;
                        }

                        for (const auto& objpath1 : topologyList)
                        {
                            auto filename =
                                sdbusplus::message::object_path(objpath1)
                                    .filename();
                            if (filename.empty())
                            {
                                BMCWEB_LOG_ERROR("Invalid object path: {}",
                                                 objpath1);
                                continue;
                            }

                            getTopologyEndDevice(asyncResp, service, objpath1,
                                                 endDevInf);
                        }
                    },
                    "xyz.openbmc_project.ObjectMapper",
                    "/xyz/openbmc_project/object_mapper",
                    "xyz.openbmc_project.ObjectMapper", "GetSubTreePaths", path,
                    0, std::array<const char*, 1>{endDevInf});
            }
        },
        service, path, "org.freedesktop.DBus.Properties", "GetAll", interface);
}

/**
 * @brief List topology phy objects and build the Oem/Ami/Topology JSON array.
 *
 * Fully parameterized so it can be used by BRCM SL7, SL8, HBA, and MSCC.
 * @param storagePrefix  URL prefix, e.g. "Raid_", "HBA_", "Raidsl8_", "mscc_"
 */
inline void getPhyTopology(
    std::shared_ptr<bmcweb::AsyncResp> asyncResp, const std::string& systemName,
    const std::string& raidName, const std::string& topologyPath,
    const std::array<std::string_view, 1>& tpgPhyInf,
    const std::string& storagePrefix)
{
    asyncResp->res.jsonValue["Oem"]["Ami"]["Topology"] =
        nlohmann::json::array();
    asyncResp->res.jsonValue["Oem"]["Ami"]["Topology@odata.count"] = 0;

    crow::connections::systemBus->async_method_call(
        [asyncResp, systemName, raidName,
         storagePrefix](const boost::system::error_code& ec,
                        const std::vector<std::string>& topologyList) {
            if (ec)
            {
                return;
            }

            nlohmann::json& tpgPhyArray =
                asyncResp->res.jsonValue["Oem"]["Ami"]["Topology"];

            for (const std::string& objpath : topologyList)
            {
                std::size_t lastPos = objpath.rfind('/');
                if (lastPos == std::string::npos ||
                    (objpath.size() <= lastPos + 1))
                {
                    BMCWEB_LOG_ERROR("Failed to find '/' in {}", objpath);
                    continue;
                }
                tpgPhyArray.push_back(
                    {{"@odata.id",
                      "/redfish/v1/Systems/" + systemName + "/Storage/" +
                          storagePrefix + raidName + "/Oem/Ami/Topology/" +
                          objpath.substr(lastPos + 1)}});
            }
            asyncResp->res.jsonValue["Oem"]["Ami"]["Topology@odata.count"] =
                tpgPhyArray.size();
        },
        "xyz.openbmc_project.ObjectMapper",
        "/xyz/openbmc_project/object_mapper",
        "xyz.openbmc_project.ObjectMapper", "GetSubTreePaths", topologyPath, 0,
        tpgPhyInf);
}

} // namespace redfish
