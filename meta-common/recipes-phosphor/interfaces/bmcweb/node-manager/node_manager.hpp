// Copyright (c) 2021 Intel Corporation
//
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

#pragma once

#include "nm_common.hpp"
#include "openbmc_dbus_rest.hpp"

#include <app.hpp>
#include <registries/privilege_registry.hpp>

#include <variant>

namespace redfish
{
inline void requestRoutesNodeManagerService(App& app)
{
    BMCWEB_ROUTE(app, "/redfish/v1/Managers/bmc/Oem/Intel/NodeManager/")
        .privileges(redfish::privileges::privilegeSetLogin)
        .methods(boost::beast::http::verb::get)(
            [](const crow::Request&,
               const std::shared_ptr<bmcweb::AsyncResp>& asyncResp) {
        crow::connections::systemBus->async_method_call(
            [asyncResp](
                const boost::system::error_code ec,
                const boost::container::flat_map<
                    std::string, std::variant<std::string, uint8_t, int32_t>>&
                    response) {
            if (ec)
            {
                BMCWEB_LOG_ERROR("respHandler DBus error: {}", ec.message());
                return;
            }

            const int32_t* health = nullptr;
            const uint8_t* maxNumberOfPolicies = nullptr;
            const std::string* version = nullptr;
            for (const auto& [key, value] : response)
            {
                if ("Health" == key)
                {
                    health = std::get_if<int32_t>(&value);
                }
                else if ("MaxNumberOfPolicies" == key)
                {
                    maxNumberOfPolicies = std::get_if<uint8_t>(&value);
                }
                else if ("Version" == key)
                {
                    version = std::get_if<std::string>(&value);
                }
            }

            if (!health || !maxNumberOfPolicies || !version)
            {
                BMCWEB_LOG_ERROR(
                    "Property type mismatch or property is missing");
                messages::internalError(asyncResp->res);
                return;
            }
            asyncResp->res.jsonValue["Status"]["Health"] =
                (*health == 0 ? "OK" : "Warning");
            asyncResp->res.jsonValue["MaxNumberOfPolicies"] =
                *maxNumberOfPolicies;
            asyncResp->res.jsonValue["NmVersion"] = *version;
            },
            "xyz.openbmc_project.NodeManager",
            "/xyz/openbmc_project/NodeManager",
            "org.freedesktop.DBus.Properties", "GetAll",
            "xyz.openbmc_project.NodeManager.NodeManager");

        getEnabled(asyncResp, "/xyz/openbmc_project/NodeManager");
        asyncResp->res.jsonValue = {
            {"@odata.type", "#NodeManager.v1_0_0.NodeManager"},
            {"@odata.id", "/redfish/v1/Managers/bmc/Oem/Intel/NodeManager"},
            {"Id", "NodeManager"},
            {"Name", "Node Manager"},
            {"Actions",
             {{"#NodeManager.ChangeState",
               {{"State@Redfish.AllowableValues", {"Enabled", "Disabled"}},
                {"target",
                 "/redfish/v1/Managers/bmc/Oem/Intel/NodeManager/Actions/NodeManager.ChangeState"}}},
              {"#NodeManager.GetDiagnosticInfo",
               {{"target",
                 "/redfish/v1/Managers/bmc/Oem/Intel/NodeManager/Actions/NodeManager.GetDiagnosticInfo"}}}}},
            {"Domains",
             {{"@odata.id",
               "/redfish/v1/Managers/bmc/Oem/Intel/NodeManager/Domains"}}},
            {"Policies",
             {{"@odata.id",
               "/redfish/v1/Managers/bmc/Oem/Intel/NodeManager/Policies"}}},
            {"Triggers",
             {{"@odata.id",
               "/redfish/v1/Managers/bmc/Oem/Intel/NodeManager/Triggers"}}},
            {"ThrottlingStatus",
             {{"@odata.id",
               "/redfish/v1/Managers/bmc/Oem/Intel/NodeManager/ThrottlingStatus"}}},
        };
        });

    BMCWEB_ROUTE(
        app,
        "/redfish/v1/Managers/bmc/Oem/Intel/NodeManager/Actions/NodeManager.ChangeState/")
        .privileges(redfish::privileges::privilegeSetConfigureManager)
        .methods(boost::beast::http::verb::post)(
            [](const crow::Request& req,
               const std::shared_ptr<bmcweb::AsyncResp>& asyncResp) {
        BMCWEB_LOG_DEBUG("NodeManager.ChangeState");

        std::string state;
        bool nmEnabled;
        if (!json_util::readJsonAction(req, asyncResp->res, "State", state))
        {
            messages::actionParameterMissing(
                asyncResp->res, "NodeManager.ChangeState", "State");
            return;
        }

        if (state == "Enabled")
        {
            nmEnabled = true;
        }
        else if (state == "Disabled")
        {
            nmEnabled = false;
        }
        else
        {
            messages::actionParameterValueFormatError(
                asyncResp->res, state, "State", "NodeManager.ChangeState");
            return;
        }

        crow::connections::systemBus->async_method_call(
            [asyncResp](const boost::system::error_code ec) {
            if (ec)
            {
                BMCWEB_LOG_DEBUG("DBUS response error {}", ec);
                messages::internalError(asyncResp->res);
                return;
            }
            BMCWEB_LOG_DEBUG("Nm.ChangeState done.");
            },
            kNodeManagerService, "/xyz/openbmc_project/NodeManager",
            "org.freedesktop.DBus.Properties", "Set",
            "xyz.openbmc_project.Object.Enable", "Enabled",
            std::variant<bool>(nmEnabled));
        return;
        });

    BMCWEB_ROUTE(
        app,
        "/redfish/v1/Managers/bmc/Oem/Intel/NodeManager/Actions/NodeManager.GetDiagnosticInfo/")
        .privileges(redfish::privileges::privilegeSetConfigureManager)
        .methods(boost::beast::http::verb::post)(
            [](const crow::Request&,
               const std::shared_ptr<bmcweb::AsyncResp>& asyncResp) {
        BMCWEB_LOG_DEBUG("NodeManager.GetDiagnosticInfo");

        crow::connections::systemBus->async_method_call(
            [asyncResp](const boost::system::error_code ec,
                        std::string& diagnostics) {
            if (ec)
            {
                BMCWEB_LOG_DEBUG(
                    "Cannot get Diagnostics from the NodeManager, error: {}",
                    ec.message());
                messages::internalError(asyncResp->res);
                return;
            }
            nlohmann::json diagsJson = nlohmann::json::parse(diagnostics);
            asyncResp->res.result(boost::beast::http::status::ok);
            asyncResp->res.write(diagsJson.dump(4));
            BMCWEB_LOG_DEBUG("NodeManager.GetDiagnosticInfo done.");
            },
            kNodeManagerService, "/xyz/openbmc_project/NodeManager/Diagnostics",
            "xyz.openbmc_project.NodeManager.Status", "DumpToJson");
        return;
        });
}

} // namespace redfish
