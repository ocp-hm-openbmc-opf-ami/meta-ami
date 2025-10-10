/*
// Copyright (c) 2021 - 2022 Intel Corporation
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

#include "utils/time_utils.hpp"

#include <app.hpp>
#include <http_request.hpp>
#include <http_response.hpp>

#include <chrono>
#include <string>

namespace redfish
{

inline void requestRoutesNodeManagerThrottlingStatus(App& app)
{
    BMCWEB_ROUTE(
        app, "/redfish/v1/Managers/bmc/Oem/Intel/NodeManager/ThrottlingStatus/")
        .privileges({{"Login"}})
        .methods(boost::beast::http::verb::get)(
            [](const crow::Request& req,
               const std::shared_ptr<bmcweb::AsyncResp>& asyncResp) {
        BMCWEB_LOG_DEBUG("Get Throttling Status");
        crow::connections::systemBus->async_method_call(
            [asyncResp, req](const boost::system::error_code& ec,
                             const std::string& throttlingEvents) {
            if (ec)
            {
                BMCWEB_LOG_ERROR("respHandler DBus error: {}", ec.message());
                nmDbus::dbusErrorToBmcwebMessage(asyncResp, req, ec,
                                                 std::nullopt);
                return;
            }
            auto dataFromDbus = nlohmann::json::parse(throttlingEvents);
            asyncResp->res.jsonValue = {
                {"@odata.type",
                 "#NmThrottlingStatus.v1_1_1.NmThrottlingStatus"},
                {"@odata.id",
                 "/redfish/v1/Managers/bmc/Oem/Intel/NodeManager/ThrottlingStatus"},
                {"Id", "ThrottlingStatus"},
                {"Name", "NM Throttling Status"},
            };

            if (!dataFromDbus.contains("ThrottlingEvents"))
            {
                BMCWEB_LOG_DEBUG(
                    "The throttling data received from Node Manager is corrupted");
                asyncResp->res.jsonValue = nlohmann::json();
                messages::internalError(asyncResp->res);
                return;
            }
            asyncResp->res.jsonValue["Events"] =
                dataFromDbus["ThrottlingEvents"];
            auto& log = asyncResp->res.jsonValue["Events"];

            unsigned int index = 0;
            for (auto& entry : log)
            {
                if (entry.contains("Start"))
                {
                    entry["StartTimestamp"] =
                        redfish::time_utils::getDateTimeUintMs(entry["Start"]);

                    if (entry["Reason"].empty() || entry["Reason"] == "")
                    {
                        if (!entry.contains("Policy") ||
                            !entry["Policy"].contains("policyParams") ||
                            !entry["Policy"].contains("domainId") ||
                            !entry["Policy"]["policyParams"].contains(
                                "triggerType"))
                        {
                            BMCWEB_LOG_DEBUG(
                                "The throttling data received from Node Manager has corrupted policy snapshot, position in the log: {}",
                                index);
                            asyncResp->res.jsonValue = nlohmann::json();
                            messages::internalError(asyncResp->res);
                            return;
                        }
                        entry["Reason"] =
                            entry["Policy"]["policyParams"]["triggerType"];
                        entry["Source"] = entry["Policy"]["domainId"];
                        entry["Policy"] = entry["Policy"].dump();
                    }
                    else
                    {
                        entry["Source"] = "SmaRTCLST";
                    }
                }
                else
                {
                    BMCWEB_LOG_DEBUG(
                        "The throttling data received from Node Manager does not contain the Start parameter, position in the log: {}",
                        index);
                    asyncResp->res.jsonValue = nlohmann::json();
                    messages::internalError(asyncResp->res);
                    return;
                }

                if (entry.contains("Stop"))
                {
                    auto duration = std::chrono::milliseconds{entry["Stop"]} -
                                    std::chrono::milliseconds{entry["Start"]};
                    entry["Duration"] = time_utils::toDurationString(duration);
                    entry["InProgress"] = false;
                    entry.erase("Stop");
                }
                else
                {
                    auto duration =
                        std::chrono::duration_cast<std::chrono::milliseconds>(
                            std::chrono::system_clock::now()
                                .time_since_epoch()) -
                        std::chrono::milliseconds{entry["Start"]};
                    entry["Duration"] = time_utils::toDurationString(duration);
                    entry["InProgress"] = true;
                }

                entry.erase("Start");
                index++;
            }
            },
            kNodeManagerService, "/xyz/openbmc_project/NodeManager/Diagnostics",
            "xyz.openbmc_project.NodeManager.Status", "GetThrottlingLog");
        });
}
} // namespace redfish
