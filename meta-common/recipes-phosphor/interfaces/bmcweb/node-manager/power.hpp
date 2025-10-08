/*
// Copyright (c) 2018 - 2021 Intel Corporation
// Copyright (c) 2018 Ampere Computing LLC
/
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
*/
#pragma once

#include "power_utility.hpp"
#include "sensors.hpp"
#include "utils/chassis_utils.hpp"

#include <boost/url/format.hpp>
#include <sdbusplus/asio/property.hpp>
#include <sdbusplus/unpack_properties.hpp>

namespace redfish
{

inline void
    getNodeManagerData(const std::shared_ptr<SensorsAsyncResp>& sensorAsyncResp)
{
    BMCWEB_LOG_DEBUG("getNodeManagerData");
    crow::connections::systemBus->async_method_call(
        [sensorAsyncResp](const boost::system::error_code ec,
                          const dbus::utility::MapperGetObject& getObjectType) {
        if (ec)
        {
            BMCWEB_LOG_ERROR("ObjectMapper::GetObject call failed: {}", ec);
        }
        std::string nmServiceName = nm::selectNmService(getObjectType);
        BMCWEB_LOG_DEBUG("Using node manager service: {}", nmServiceName);
        nm::getComponents(
            sensorAsyncResp, nmServiceName,
            [sensorAsyncResp,
             nmServiceName](const std::vector<nm::DeviceIndex>& processors,
                            const std::vector<nm::DeviceIndex>& memories,
                            const std::vector<nm::DeviceIndex>& accelerators) {
            nm::collectNmDmtfData(sensorAsyncResp, nmServiceName, processors,
                                  memories, accelerators);
            });
        },
        "xyz.openbmc_project.ObjectMapper",
        "/xyz/openbmc_project/object_mapper",
        "xyz.openbmc_project.ObjectMapper", "GetObject",
        "/xyz/openbmc_project/NodeManager", std::array<const char*, 0>());
}

inline void setPowerCapOverride(
    const std::shared_ptr<SensorsAsyncResp>& sensorsAsyncResp,
    const std::string& nmServiceName,
    std::vector<nlohmann::json>& powerControlCollections)
{
    BMCWEB_LOG_DEBUG("setPowerCapOverride");
    auto getChassisPath =
        [sensorsAsyncResp, powerControlCollections,
         nmServiceName](const std::optional<std::string>& chassisPath) mutable {
        if (!chassisPath)
        {
            BMCWEB_LOG_ERROR("Don't find valid chassis path");
            messages::resourceNotFound(sensorsAsyncResp->asyncResp->res,
                                       "Chassis", sensorsAsyncResp->chassisId);
            return;
        }

        if (powerControlCollections.empty())
        {
            return;
        }

        nm::getComponents(
            sensorsAsyncResp, nmServiceName,
            [sensorsAsyncResp, nmServiceName, powerControlCollections](
                const std::vector<nm::DeviceIndex>& processors,
                const std::vector<nm::DeviceIndex>& memories,
                const std::vector<nm::DeviceIndex>& accelerators) {
            std::vector<std::tuple<nm::DomainId, nm::PolicyId, nm::DeviceIndex,
                                   std::string>>
                list;
            nm::buildDomainPolicyMap(processors, memories, accelerators, list);

            size_t i = 0;
            for (auto& it : powerControlCollections)
            {
                const auto& [domain, policy, deviceIndex,
                             memberId] = list.at(i);
                std::optional<nlohmann::json> oem;
                std::optional<nlohmann::json> powerLimit;
                nlohmann::json collection = it;
                if (!json_util::readJson(collection,
                                         sensorsAsyncResp->asyncResp->res,
                                         "Oem", oem, "PowerLimit", powerLimit))
                {
                    return;
                }
                if (oem)
                {
                    nm::patchPowerPowerControlOem(sensorsAsyncResp, domain,
                                                  policy, nmServiceName, *oem);
                }
                if (powerLimit)
                {
                    nm::patchPowerPowerControlPowerLimit(
                        sensorsAsyncResp, domain, policy, deviceIndex,
                        nmServiceName, *powerLimit);
                }
                if (oem)
                {
                    nm::patchPowerPowerControlOem(sensorsAsyncResp, domain,
                                                  policy, nmServiceName, *oem);
                }

                i++;
            }
            });
    };
    redfish::chassis_utils::getValidChassisPath(sensorsAsyncResp->asyncResp,
                                                sensorsAsyncResp->chassisId,
                                                std::move(getChassisPath));
}

bool chassisHandler(const std::shared_ptr<SensorsAsyncResp>& sensorAsyncResp,
                    const boost::system::error_code e,
                    const std::vector<std::string>& chassisPaths)
{
    // This callback verifies that the power limit is only provided
    // for the chassis that implements the Chassis inventory item.
    // This prevents things like power supplies providing the
    // chassis power limit
    if (e)
    {
        BMCWEB_LOG_ERROR("Power Limit GetSubTreePaths handler Dbus error {}",
                         e);
        return false;
    }

    bool found = false;
    for (const std::string& chassis : chassisPaths)
    {
        size_t len = std::string::npos;
        size_t lastPos = chassis.rfind('/');
        if (lastPos == std::string::npos)
        {
            continue;
        }

        if (lastPos == chassis.size() - 1)
        {
            size_t end = lastPos;
            lastPos = chassis.rfind('/', lastPos - 1);
            if (lastPos == std::string::npos)
            {
                continue;
            }

            len = end - (lastPos + 1);
        }

        std::string interfaceChassisName = chassis.substr(lastPos + 1, len);
        if (!interfaceChassisName.compare(sensorAsyncResp->chassisId))
        {
            found = true;
            break;
        }
    }

    if (!found)
    {
        BMCWEB_LOG_DEBUG("Power Limit not present for {}",
                         sensorAsyncResp->chassisId);
        return false;
    }

    return true;
}

inline void doPowerHeader(const std::shared_ptr<bmcweb::AsyncResp>& asyncResp,
                          const std::string& chassisId,
                          const std::optional<std::string>& validChassisPath)
{
    if (!validChassisPath)
    {
        messages::resourceNotFound(asyncResp->res, "Chassis", chassisId);
        return;
    }

    asyncResp->res.addHeader(
        boost::beast::http::field::link,
        "</redfish/v1/JsonSchemas/Power/Power.json>; rel=describedby");
    asyncResp->res.jsonValue["@odata.type"] = "#Power.v1_5_2.Power";
    asyncResp->res.jsonValue["Name"] = "Power";
    asyncResp->res.jsonValue["Id"] = "Power";
    asyncResp->res.jsonValue["@odata.id"] =
        boost::urls::format("/redfish/v1/Chassis/{}/Power", chassisId);
}

inline void requestRoutesPower(App& app)
{
    BMCWEB_ROUTE(app, "/redfish/v1/Chassis/<str>/Power/")
        .privileges(redfish::privileges::privilegeSetLogin)
        .methods(boost::beast::http::verb::get)(
            [](const crow::Request&,
               const std::shared_ptr<bmcweb::AsyncResp>& asyncResp,
               const std::string& chassisName) {
        redfish::chassis_utils::getValidChassisPath(
            asyncResp, chassisName,
            std::bind_front(doPowerHeader, asyncResp, chassisName));

        asyncResp->res.jsonValue["PowerControl"] = nlohmann::json::array();

        auto sensorAsyncResp = std::make_shared<SensorsAsyncResp>(
            asyncResp, chassisName, sensors::dbus::powerPaths,
            sensors::node::power);

        crow::connections::systemBus->async_method_call(
            [sensorAsyncResp](const boost::system::error_code e,
                              const std::vector<std::string>& chassisPaths) {
            if (chassisHandler(sensorAsyncResp, e, chassisPaths))
            {
                getNodeManagerData(sensorAsyncResp);
            }
            },
            "xyz.openbmc_project.ObjectMapper",
            "/xyz/openbmc_project/object_mapper",
            "xyz.openbmc_project.ObjectMapper", "GetSubTreePaths",
            "/xyz/openbmc_project/inventory", 0,
            std::array<const char*, 2>{
                "xyz.openbmc_project.Inventory.Item.Board",
                "xyz.openbmc_project.Inventory.Item.Chassis"});
        });

    BMCWEB_ROUTE(app, "/redfish/v1/Chassis/<str>/Power/PowerControl/<str>")
        .privileges({{"Login"}})
        .methods(boost::beast::http::verb::get)(
            [](const crow::Request&,
               const std::shared_ptr<bmcweb::AsyncResp>& asyncResp,
               const std::string& chassisName, const std::string& node) {
        auto sensorAsyncResp = std::make_shared<SensorsAsyncResp>(
            asyncResp, chassisName, sensors::dbus::powerPaths,
            sensors::node::power);

        crow::connections::systemBus->async_method_call(
            [sensorAsyncResp,
             node](const boost::system::error_code e,
                   const std::vector<std::string>& chassisPaths) {
            if (chassisHandler(sensorAsyncResp, e, chassisPaths))
            {
                nm::getNmDmtfComponentByMemberId(sensorAsyncResp, node);
            }
            },
            "xyz.openbmc_project.ObjectMapper",
            "/xyz/openbmc_project/object_mapper",
            "xyz.openbmc_project.ObjectMapper", "GetSubTreePaths",
            "/xyz/openbmc_project/inventory", 0,
            std::array<const char*, 2>{
                "xyz.openbmc_project.Inventory.Item.Board",
                "xyz.openbmc_project.Inventory.Item.Chassis"});
        });

    BMCWEB_ROUTE(app, "/redfish/v1/Chassis/<str>/Power/PowerControl/<str>")
        .privileges({{"ConfigureManager"}})
        .methods(boost::beast::http::verb::patch)(
            [](const crow::Request& req,
               const std::shared_ptr<bmcweb::AsyncResp>& asyncResp,
               const std::string& chassisName, const std::string& node) {
        auto sensorAsyncResp = std::make_shared<SensorsAsyncResp>(
            asyncResp, chassisName, sensors::dbus::powerPaths,
            sensors::node::power);

        crow::connections::systemBus->async_method_call(
            [req, sensorAsyncResp,
             node](const boost::system::error_code e,
                   const std::vector<std::string>& chassisPaths) {
            if (chassisHandler(sensorAsyncResp, e, chassisPaths))
            {
                nm::patchNmDmtfComponentByMemberId(req, sensorAsyncResp, node);
            }
            },
            "xyz.openbmc_project.ObjectMapper",
            "/xyz/openbmc_project/object_mapper",
            "xyz.openbmc_project.ObjectMapper", "GetSubTreePaths",
            "/xyz/openbmc_project/inventory", 0,
            std::array<const char*, 2>{
                "xyz.openbmc_project.Inventory.Item.Board",
                "xyz.openbmc_project.Inventory.Item.Chassis"});
        });

    BMCWEB_ROUTE(app, "/redfish/v1/Chassis/<str>/Power/")
        .privileges(redfish::privileges::privilegeSetConfigureManager)
        .methods(boost::beast::http::verb::patch)(
            [](const crow::Request& req,
               const std::shared_ptr<bmcweb::AsyncResp>& asyncResp,
               const std::string& chassisName) {
        auto sensorAsyncResp = std::make_shared<SensorsAsyncResp>(
            asyncResp, chassisName, sensors::dbus::powerPaths,
            sensors::node::power);
        sensorAsyncResp->asyncResp->res.result(
            boost::beast::http::status::no_content);

        crow::connections::systemBus->async_method_call(
            [sensorAsyncResp,
             req](const boost::system::error_code ec,
                  const dbus::utility::MapperGetObject& getObjectType) {
            if (ec)
            {
                BMCWEB_LOG_ERROR("ObjectMapper::GetObject call failed: {}", ec);
                messages::internalError(sensorAsyncResp->asyncResp->res);
                return;
            }

            const std::string& nmServiceName =
                nm::selectNmService(getObjectType);
            BMCWEB_LOG_DEBUG("Using node manager service: {}", nmServiceName);

            std::optional<std::vector<nlohmann::json>> powerCtlCollections;

            if (!json_util::readJsonAction(req, sensorAsyncResp->asyncResp->res,
                                           "PowerControl", powerCtlCollections))
            {
                return;
            }

            if (powerCtlCollections)
            {
                setPowerCapOverride(sensorAsyncResp, nmServiceName,
                                    *powerCtlCollections);
            }
            },
            "xyz.openbmc_project.ObjectMapper",
            "/xyz/openbmc_project/object_mapper",
            "xyz.openbmc_project.ObjectMapper", "GetObject",
            "/xyz/openbmc_project/NodeManager", std::array<const char*, 0>());
        });
}

} // namespace redfish
