/*
// Copyright (c) 2021-2022 Intel Corporation
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

#include <app.hpp>
#include <http_request.hpp>
#include <http_response.hpp>

#include <string>

namespace redfish
{

static void getTriggerData(const std::shared_ptr<bmcweb::AsyncResp>& asyncResp,
                           const std::string& dbusPath)
{
    crow::connections::systemBus->async_method_call(
        [asyncResp](
            const boost::system::error_code ec,
            const boost::container::flat_map<
                std::string, std::variant<uint16_t, std::string>>& params) {
        if (ec)
        {
            BMCWEB_LOG_ERROR("respHandler DBus error: {}", ec.message());
            messages::internalError(asyncResp->res);
            return;
        }

        const uint16_t* max = nullptr;
        const uint16_t* min = nullptr;
        const std::string* unit = nullptr;

        for (const auto& [key, value] : params)
        {
            if ("Max" == key)
            {
                max = std::get_if<uint16_t>(&value);
            }
            else if ("Min" == key)
            {
                min = std::get_if<uint16_t>(&value);
            }
            else if ("Unit" == key)
            {
                unit = std::get_if<std::string>(&value);
            }
        }

        if (max)
        {
            asyncResp->res.jsonValue["Max"] = *max;
        }
        if (min)
        {
            asyncResp->res.jsonValue["Min"] = *min;
        }
        if (unit)
        {
            asyncResp->res.jsonValue["Unit"] = *unit;
        }
        },
        kNodeManagerService, dbusPath, "org.freedesktop.DBus.Properties",
        "GetAll", "xyz.openbmc_project.NodeManager.Trigger");
}

static void getGpioLines(std::shared_ptr<bmcweb::AsyncResp> asyncResp,
                         const std::string& dbusPath)
{
    const std::array<const char*, 1> interfaces{
        "xyz.openbmc_project.NodeManager.Trigger.GPIO"};
    const char* subtree{"/xyz/openbmc_project/NodeManager/Trigger/GPIO"};
    crow::connections::systemBus->async_method_call(
        [dbusPath, asyncResp{std::move(asyncResp)}](
            const boost::system::error_code ec,
            const std::vector<std::string>& objects) {
        if (ec)
        {
            BMCWEB_LOG_DEBUG("DBUS response error {}", ec.value());
            messages::internalError(asyncResp->res);
            return;
        }

        std::vector<std::string> lineNames;
        for (const auto& object : objects)
        {
            sdbusplus::message::object_path path(object);
            std::string lineName = path.filename();
            if (lineName.empty())
            {
                continue;
            }
            lineNames.push_back(lineName);
        }

        asyncResp->res.jsonValue["TriggerValues"] = nlohmann::json(lineNames);
        },
        "xyz.openbmc_project.ObjectMapper",
        "/xyz/openbmc_project/object_mapper",
        "xyz.openbmc_project.ObjectMapper", "GetSubTreePaths", subtree, 0,
        interfaces);
}

inline void requestRoutesNodeManagerTriggers(App& app)
{
    BMCWEB_ROUTE(app, "/redfish/v1/Managers/bmc/Oem/Intel/NodeManager/Triggers/")
        .privileges(redfish::privileges::privilegeSetLogin)
        .methods(boost::beast::http::verb::get)(
            [](const crow::Request&,
               const std::shared_ptr<bmcweb::AsyncResp>& asyncResp) {
        asyncResp->res.jsonValue = {
            {"@odata.type", "#NmTriggerCollection.NmTriggerCollection"},
            {"@odata.id",
             "/redfish/v1/Managers/bmc/Oem/Intel/NodeManager/Triggers"},
            {"Name", "NM Triggers Collection"},
        };

        constexpr std::array<std::string_view, 1> interface {
            "xyz.openbmc_project.NodeManager.Trigger"
        };

        collection_util::getCollectionMembers(
            asyncResp,
            boost::urls::url(
                "/redfish/v1/Managers/bmc/Oem/Intel/NodeManager/Triggers"),
            interface, "/xyz/openbmc_project/NodeManager");
        });

    BMCWEB_ROUTE(
        app, "/redfish/v1/Managers/bmc/Oem/Intel/NodeManager/Triggers/<str>/")
        .privileges(redfish::privileges::privilegeSetLogin)
        .methods(boost::beast::http::verb::get)(
            [](const crow::Request&,
               const std::shared_ptr<bmcweb::AsyncResp>& asyncResp,
               const std::string& triggerName) {
        auto triggerDbusPath = "/xyz/openbmc_project/NodeManager/Trigger/" +
                               triggerName;

        getTriggerData(asyncResp, triggerDbusPath);

        if (triggerName == "GPIO")
        {
            getGpioLines(asyncResp, triggerDbusPath);
        }

        asyncResp->res.jsonValue = {
            {"@odata.type", "#NmTrigger.v1_0_0.NmTrigger"},
            {"@odata.id",
             "/redfish/v1/Managers/bmc/Oem/Intel/NodeManager/Triggers/" +
                 triggerName},
            {"Id", triggerName},
            {"Name", triggerName},
        };
        });
}
} // namespace redfish
