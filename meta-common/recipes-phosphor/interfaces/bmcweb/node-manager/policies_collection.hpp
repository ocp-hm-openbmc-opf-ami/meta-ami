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

#include "dbus_utility.hpp"
#include "error_messages.hpp"
#include "nm_common.hpp"

#include <app.hpp>
#include <http_request.hpp>
#include <http_response.hpp>

#include <optional>
#include <string>
#include <vector>

namespace redfish
{

constexpr const char* kPolicyAttributesInterface =
    "xyz.openbmc_project.NodeManager.PolicyAttributes";
constexpr const char* kPolicyStatisticsInterface =
    "xyz.openbmc_project.NodeManager.Statistics";
constexpr const char* kPolicyManagerInterface =
    "xyz.openbmc_project.NodeManager.PolicyManager";
constexpr const char* kPowerPolicyType = "PowerPolicy";

constexpr const char* kHwProtectionDomainId = "HWProtection";

using SuspendPeriodsType = std::vector<
    std::map<std::string, std::variant<std::vector<std::string>, std::string>>>;
using ThresholdsType = std::map<std::string, std::vector<uint16_t>>;

using PolicyParamsTuple = std::tuple<uint32_t, // 0 - correctionInMs
                                     uint16_t, // 1 - limit
                                     uint16_t, // 2 - statReportingPeriod
                                     int32_t,  // 3 - policyStorage
                                     int32_t,  // 4 - powerCorrectionType
                                     int32_t,  // 5 - limitException
                                     SuspendPeriodsType, // 6 - suspendPeriods
                                     ThresholdsType,     // 7 - thresholds
                                     uint8_t,            // 8 - componentId
                                     uint16_t,           // 9- triggerLimit
                                     std::string         // 10- triggerType
                                     >;

static const boost::container::flat_map<int32_t, std::string>
    kPolicyStorageMap = {{0, "Persistent"}, {1, "Volatile"}};

static const boost::container::flat_map<int32_t, std::string>
    kPowerCorrectionTypeMap = {
        {0, "Auto"}, {1, "NonAggressive"}, {2, "Aggressive"}};

static const boost::container::flat_map<int32_t, std::string>
    kLimitExceptionMap = {
        {0, "NoAction"}, {1, "HardPowerOff"}, {2, "LogEventOnly"}, {3, "Oem"}};

static const boost::container::flat_map<bool, std::string> kPolicyStateMap = {
    {false, "Disabled"}, {true, "Enabled"}};

enum class PolicyState : int32_t
{
    pending = 0,
    disabled = 1,
    ready = 2,
    triggered = 3,
    selected = 4,
    suspended = 5
};

static const boost::container::flat_map<int32_t, std::string>
    kPolicyOemStateMap = {{0, "Pending"},   {1, "Disabled"}, {2, "Ready"},
                          {3, "Triggered"}, {4, "Selected"}, {5, "Suspended"}};

static const std::set<int32_t> kPolicyStatesEnabled = {0, 2, 3, 4, 5};

inline bool isPolicyStateEnabled(int32_t state)
{
    return kPolicyStatesEnabled.contains(state);
}

inline bool isPolicyReadOnly(
    const std::vector<std::pair<std::string, dbus::utility::DbusVariantType>>&
        properties)
{
    if (auto owner = getPropertyValue<int32_t>(properties, "Owner"))
    {
        return (*owner != kPolicyOwnerBmc);
    }
    return false;
}

inline bool isHwProtectionPolicy(
    const std::vector<std::pair<std::string, dbus::utility::DbusVariantType>>&
        properties)
{
    if (auto domainId = getPropertyValue<std::string>(properties, "DomainId"))
    {
        return (*domainId == kHwProtectionDomainId);
    }
    return false;
}

inline void getAttributes(const std::shared_ptr<bmcweb::AsyncResp>& response,
                          const std::string& policyObjectPath)
{
    sdbusplus::asio::getAllProperties(
        *crow::connections::systemBus, kNodeManagerService, policyObjectPath,
        kPolicyAttributesInterface,
        [response](boost::system::error_code ec,
                   const std::vector<
                       std::pair<std::string, dbus::utility::DbusVariantType>>&
                       properties) {
        if (ec)
        {
            messages::internalError(response->res);
            return;
        }

        auto policyName = getPropertyValue<std::string>(properties, "Id");
        if (!policyName)
        {
            messages::internalError(response->res);
            return;
        }
        response->res.jsonValue["@odata.id"] =
            "/redfish/v1/Managers/bmc/Oem/Intel/NodeManager/Policies/" +
            *policyName;
        response->res.jsonValue["@odata.type"] = "#NmPolicy.v1_2_0.NmPolicy";
        response->res.jsonValue["Actions"]["#NmPolicy.ResetStatistics"] = {
            {"target",
             "/redfish/v1/Managers/bmc/Oem/Intel/NodeManager/Policies/" +
                 *policyName + "/Actions/Policy.ResetStatistics"}};

        if (isHwProtectionPolicy(properties) || !isPolicyReadOnly(properties))
        {
            response->res.jsonValue["Actions"]["#NmPolicy.ChangeState"] = {
                {"State@Redfish.AllowableValues", {"Enabled", "Disabled"}},
                {"target",
                 "/redfish/v1/Managers/bmc/Oem/Intel/NodeManager/Policies/" +
                     *policyName + "/Actions/Policy.ChangeState"}};
        }
        response->res.jsonValue["Thresholds"]["ThresholdValue"] =
            nlohmann::json::array();
        response->res.jsonValue["SuspendPeriods"] = nlohmann::json::object();
        parsePropertyToResponse<uint8_t>(response, properties, "ComponentId");
        parsePropertyToResponse<uint16_t>(response, properties, "Limit");
        parsePropertyToResponse<int32_t>(response, properties, "PolicyStorage",
                                         kPolicyStorageMap);
        response->res.jsonValue["Id"] = *policyName;
        response->res.jsonValue["Name"] = "Policy" + *policyName;
        parsePropertyToResponse<std::string>(
            response, properties, "PolicyType",
            [&response, &properties](std::string& policyType) {
            response->res.jsonValue["PolicyType"] = policyType;
            if (policyType == kPowerPolicyType)
            {
                parsePropertyToResponse<uint32_t>(response, properties,
                                                  "CorrectionInMs");
                parsePropertyToResponse<int32_t>(response, properties,
                                                 "PowerCorrectionType",
                                                 kPowerCorrectionTypeMap);
                parsePropertyToResponse<int32_t>(
                    response, properties, "LimitException", kLimitExceptionMap);
            }
            });
        parsePropertyToResponse<uint16_t>(response, properties,
                                          "StatisticsReportingPeriod",
                                          [&response](uint16_t s) {
            auto ms = std::chrono::duration_cast<std::chrono::milliseconds>(
                std::chrono::seconds(s));
            response->res.jsonValue["StatisticsReportingPeriod"] =
                time_utils::toDurationString(ms);
        });
        parsePropertyToResponse<std::string>(
            response, properties, "DomainId",
            [&response](std::string& domainName) {
            response->res.jsonValue["Domain"]["@odata.id"] =
                "/redfish/v1/Managers/bmc/Oem/Intel/NodeManager/Domains/" +
                domainName;
            });
        parsePropertyToResponse<int32_t>(response, properties, "PolicyState",
                                         kPolicyOemStateMap,
                                         [&response](std::string state) {
            response->res.jsonValue["OemStatus"] = state;
        });
        parsePropertyToResponse<int32_t>(response, properties, "PolicyState",
                                         [&response](int32_t state) {
            std::string dmtfState = "Disabled";
            if (isPolicyStateEnabled(state))
            {
                dmtfState = "Enabled";
            }
            response->res.jsonValue["Status"]["State"] = dmtfState;
        });
        parsePropertyToResponse<std::string>(response, properties,
                                             "TriggerType",
                                             [&response](std::string& trigger) {
            response->res.jsonValue["Trigger"]["TriggerType"]["@odata.id"] =
                "/redfish/v1/Managers/bmc/Oem/Intel/NodeManager/Triggers/" +
                trigger;
        });
        parsePropertyToResponse<uint16_t>(response, properties, "TriggerLimit",
                                          [&response](uint16_t triggerLimit) {
            response->res.jsonValue["Trigger"]["TriggerLimit"] = triggerLimit;
        });
        });
}

static void deletePolicy(const std::shared_ptr<bmcweb::AsyncResp>& asyncResp,
                         const std::string& policyId)
{
    auto removePolicy =
        [asyncResp,
         policyId](const boost::system::error_code& ec,
                   const std::vector<sdbusplus::message::object_path>& paths) {
        if (ec)
        {
            BMCWEB_LOG_ERROR("respHandler DBus error: {}", ec.message());
            messages::internalError(asyncResp->res);
            return;
        }
        if (paths.size() != 1)
        {
            messages::resourceNotFound(asyncResp->res, "Policies", policyId);
            return;
        }
        auto policyPath = paths[0];
        BMCWEB_LOG_DEBUG("Deleting policy: {}", policyPath.str);
        crow::connections::systemBus->async_method_call(
            [asyncResp, policyPath](const boost::system::error_code ec2) {
            if (ec2)
            {
                if (static_cast<nmDbus::ErrorCodes>(ec2.value()) ==
                    nmDbus::ErrorCodes::OperationNotPermitted)
                {
                    messages::resourceCannotBeDeleted(asyncResp->res);
                }
                else
                {
                    messages::resourceNotFound(asyncResp->res, "Policies",
                                               policyPath.str);
                }

                return;
            }
            BMCWEB_LOG_INFO("Policy deleted: {}", policyPath.str);
            asyncResp->res.result(boost::beast::http::status::no_content);
            },
            kNodeManagerService, policyPath.str,
            "xyz.openbmc_project.Object.Delete", "Delete");
    };
    asyncFindPolicies(removePolicy,
                      [policyId](const nmDbus::DBusPropertiesMap& propMap) {
        return createAttributePredicate("Id", policyId)(propMap) &&
               createAttributePredicate("Owner", kPolicyOwnerBmc)(propMap);
    });
}

bool convertAttributesToPolicyParams(
    const std::vector<std::pair<std::string, dbus::utility::DbusVariantType>>&
        properties,
    PolicyParamsTuple& policyParams)
{
    auto correctionInMs = getPropertyValue<uint32_t>(properties,
                                                     "CorrectionInMs");
    auto limit = getPropertyValue<uint16_t>(properties, "Limit");
    auto statisticsReportingPeriod =
        getPropertyValue<uint16_t>(properties, "StatisticsReportingPeriod");
    auto policyStorage = getPropertyValue<int32_t>(properties, "PolicyStorage");
    auto powerCorrectionType = getPropertyValue<int32_t>(properties,
                                                         "PowerCorrectionType");
    auto limitException = getPropertyValue<int32_t>(properties,
                                                    "LimitException");
    auto componentId = getPropertyValue<uint8_t>(properties, "ComponentId");
    auto triggerLimit = getPropertyValue<uint16_t>(properties, "TriggerLimit");
    auto triggerType = getPropertyValue<std::string>(properties, "TriggerType");

    if (correctionInMs == std::nullopt || limit == std::nullopt ||
        statisticsReportingPeriod == std::nullopt ||
        policyStorage == std::nullopt || powerCorrectionType == std::nullopt ||
        limitException == std::nullopt || componentId == std::nullopt ||
        triggerLimit == std::nullopt || triggerType == std::nullopt)
    {
        return false;
    }

    policyParams = PolicyParamsTuple(
        *correctionInMs, *limit, *statisticsReportingPeriod, *policyStorage,
        *powerCorrectionType, *limitException, SuspendPeriodsType(),
        ThresholdsType(), *componentId, *triggerLimit, *triggerType);
    return true;
}

inline void updatePolicyParamsWithJsonValues(
    const crow::Request& req,
    const std::shared_ptr<bmcweb::AsyncResp>& asyncResp,
    PolicyParamsTuple& policyParams)
{
    std::optional<uint32_t> correctionInMs;
    std::optional<uint16_t> limit;
    std::optional<std::string> statisticsReportingPeriodStr;
    std::optional<std::string> policyStorage;
    std::optional<std::string> powerCorrectionType;
    std::optional<std::string> limitException;
    std::optional<uint8_t> componentId;
    std::optional<nlohmann::json> trigger;
    if (!json_util::readJsonAction(
            req, asyncResp->res, "CorrectionInMs", correctionInMs, "Limit",
            limit, "StatisticsReportingPeriod", statisticsReportingPeriodStr,
            "PolicyStorage", policyStorage, "PowerCorrectionType",
            powerCorrectionType, "LimitException", limitException,
            "ComponentId", componentId, "Trigger", trigger))
    {
        messages::malformedJSON(asyncResp->res);
        return;
    }

    if (correctionInMs)
    {
        std::get<0>(policyParams) = *correctionInMs;
    }
    if (limit)
    {
        std::get<1>(policyParams) = *limit;
    }
    if (statisticsReportingPeriodStr)
    {
        std::get<2>(policyParams) = convertTimeString<uint16_t>(
            asyncResp, *statisticsReportingPeriodStr,
            "StatisticsReportingPeriod");
    }
    if (policyStorage)
    {
        auto policyStorageDbus = std::find_if(
            kPolicyStorageMap.begin(), kPolicyStorageMap.end(),
            [&policyStorage](const std::pair<int32_t, std::string>& option) {
            return *policyStorage == option.second;
            });
        if (policyStorageDbus != kPolicyStorageMap.end())
        {
            std::get<3>(policyParams) = policyStorageDbus->first;
        }
        else
        {
            messages::propertyValueIncorrect(asyncResp->res, "PolicyStorage",
                                             *policyStorage);
        }
    }
    if (powerCorrectionType)
    {
        auto powerCorrectionTypeDbus = std::find_if(
            kPowerCorrectionTypeMap.begin(), kPowerCorrectionTypeMap.end(),
            [&powerCorrectionType](
                const std::pair<int32_t, std::string>& option) {
            return *powerCorrectionType == option.second;
            });
        if (powerCorrectionTypeDbus != kPowerCorrectionTypeMap.end())
        {
            std::get<4>(policyParams) = powerCorrectionTypeDbus->first;
        }
        else
        {
            messages::propertyValueIncorrect(
                asyncResp->res, "PowerCorrectionType", *powerCorrectionType);
        }
    }
    if (limitException)
    {
        auto limitExceptionDbus = std::find_if(
            kLimitExceptionMap.begin(), kLimitExceptionMap.end(),
            [&limitException](const std::pair<int32_t, std::string>& option) {
            return *limitException == option.second;
            });
        if (limitExceptionDbus != kLimitExceptionMap.end())
        {
            std::get<5>(policyParams) = limitExceptionDbus->first;
        }
        else
        {
            messages::propertyValueIncorrect(asyncResp->res, "LimitException",
                                             *limitException);
        }
    }
    if (componentId)
    {
        std::get<8>(policyParams) = *componentId;
    }
    if (trigger)
    {
        std::optional<uint16_t> triggerLimit;
        std::optional<std::string> triggerType;

        if (!json_util::readJson(*trigger, asyncResp->res, "TriggerLimit",
                                 triggerLimit, "TriggerType", triggerType))
        {
            messages::malformedJSON(asyncResp->res);
            return;
        }
        if (triggerLimit)
        {
            std::get<9>(policyParams) = *triggerLimit;
        }
        if (triggerType)
        {
            std::get<10>(policyParams) = *triggerType;
        }
    }
}

void getPolicyObjectPath(const crow::Request& req,
                         const std::shared_ptr<bmcweb::AsyncResp>& asyncResp,
                         const std::string& policyName,
                         std::function<void(const std::string&)> handler)
{
    crow::connections::systemBus->async_method_call(
        [req, asyncResp, policyName,
         handler](const boost::system::error_code ec,
                  const std::vector<std::string>& objects) {
        if (ec)
        {
            BMCWEB_LOG_ERROR("respHandler DBus error: {}", ec.message());
            messages::internalError(asyncResp->res);
        }

        auto policyObjectPath =
            std::find_if(objects.begin(), objects.end(),
                         [&policyName](const std::string& objectPath) {
            std::smatch match;
            std::regex search("Policy/" + policyName + "$");
            if (std::regex_search(objectPath, match, search))
            {
                return true;
            }
            return false;
            });

        if (objects.end() == policyObjectPath)
        {
            messages::resourceNotFound(asyncResp->res, "Policies", policyName);
            return;
        }
        std::string policyObjectPathValue = *policyObjectPath;
        handler(policyObjectPathValue);
        },
        kObjectMapperService, kObjectMapperObjectPath, kObjectMapperService,
        "GetSubTreePaths", kNodeManagerObjectPath, 0,
        std::vector<const char*>{kPolicyAttributesInterface});
}

inline void requestRoutesNodeManagerPolicies(App& app)
{
    sd_bus_error_add_map(nmDbus::kNodeManagerDBusErrors);

    BMCWEB_ROUTE(app, "/redfish/v1/Managers/bmc/Oem/Intel/NodeManager/Policies/")
        .privileges(redfish::privileges::privilegeSetLogin)
        .methods(boost::beast::http::verb::get)(
            [](const crow::Request&,
               const std::shared_ptr<bmcweb::AsyncResp>& asyncResp) {
        asyncResp->res.jsonValue = {
            {"@odata.type", "#NmPolicyCollection.v1_0_0.NmPolicyCollection"},
            {"@odata.id",
             "/redfish/v1/Managers/bmc/Oem/Intel/NodeManager/Policies"},
            {"Name", "NM Policies Collection"},
        };

        auto addPolicies =
            [asyncResp](
                const boost::system::error_code& ec,
                const std::vector<sdbusplus::message::object_path>& paths) {
            if (ec)
            {
                BMCWEB_LOG_ERROR("respHandler DBus error: {}", ec.message());
                messages::internalError(asyncResp->res);
                return;
            }
            nlohmann::json& members = asyncResp->res.jsonValue["Members"];
            members = dbusPoliciesPathsToLinks(paths);
            asyncResp->res.jsonValue["Members@odata.count"] = members.size();
        };

        asyncFindPolicies(addPolicies, nullptr);
        });

    BMCWEB_ROUTE(
        app, "/redfish/v1/Managers/bmc/Oem/Intel/NodeManager/Policies/<str>")
        .privileges(redfish::privileges::privilegeSetLogin)
        .methods(boost::beast::http::verb::get)(
            [](const crow::Request&,
               const std::shared_ptr<bmcweb::AsyncResp>& asyncResp,
               const std::string& policyName) {
        crow::connections::systemBus->async_method_call(
            [asyncResp, policyName](const boost::system::error_code ec,
                                    const std::vector<std::string>& objects) {
            if (ec)
            {
                BMCWEB_LOG_ERROR("respHandler DBus error: {}", ec.message());
                messages::internalError(asyncResp->res);
            }

            auto policyObjectPath =
                std::find_if(objects.begin(), objects.end(),
                             [&policyName](const std::string& objectPath) {
                std::smatch match;
                std::regex search("Policy/" + policyName + "$");
                if (std::regex_search(objectPath, match, search))
                {
                    return true;
                }
                return false;
                });

            if (objects.end() == policyObjectPath)
            {
                messages::resourceNotFound(asyncResp->res, "Policies",
                                           policyName);
                return;
            }

            getAttributes(asyncResp, *policyObjectPath);
            getStatistics(asyncResp, *policyObjectPath);
            },
            kObjectMapperService, kObjectMapperObjectPath, kObjectMapperService,
            "GetSubTreePaths", kNodeManagerObjectPath, 0,
            std::vector<const char*>{kPolicyAttributesInterface});
        });

    BMCWEB_ROUTE(
        app, "/redfish/v1/Managers/bmc/Oem/Intel/NodeManager/Policies/<str>/")
        .privileges(redfish::privileges::privilegeSetConfigureManager)
        .methods(boost::beast::http::verb::delete_)(
            [](const crow::Request&,
               const std::shared_ptr<bmcweb::AsyncResp>& asyncResp,
               const std::string& policyName) {
        if (policyName.empty())
        {
            messages::internalError(asyncResp->res);
            return;
        }
        deletePolicy(asyncResp, policyName);
        });

    BMCWEB_ROUTE(
        app, "/redfish/v1/Managers/bmc/Oem/Intel/NodeManager/Policies/<str>/")
        .privileges(redfish::privileges::privilegeSetConfigureManager)
        .methods(boost::beast::http::verb::patch)(
            [](const crow::Request& req,
               const std::shared_ptr<bmcweb::AsyncResp>& asyncResp,
               const std::string& policyName) {
        getPolicyObjectPath(
            req, asyncResp, policyName,
            [req, asyncResp, policyName](const std::string& policyObjectPath) {
            sdbusplus::asio::getAllProperties(
                *crow::connections::systemBus, kNodeManagerService,
                policyObjectPath, kPolicyAttributesInterface,
                [req, asyncResp, policyObjectPath, policyName](
                    boost::system::error_code ec,
                    const std::vector<
                        std::pair<std::string, dbus::utility::DbusVariantType>>&
                        properties) {
                if (ec)
                {
                    BMCWEB_LOG_ERROR("Cannot get properties for policy: {}",
                                     policyObjectPath);
                    messages::internalError(asyncResp->res);
                    return;
                }
                if (isPolicyReadOnly(properties))
                {
                    BMCWEB_LOG_INFO(
                        "The attempt to modify the object has been denied: {}",
                        policyObjectPath);
                    messages::operationNotAllowed(asyncResp->res);
                    return;
                }

                PolicyParamsTuple policyParams;
                if (!convertAttributesToPolicyParams(properties, policyParams))
                {
                    BMCWEB_LOG_ERROR(
                        "Parameters conversion has failed for policy: {}",
                        policyObjectPath);
                    messages::internalError(asyncResp->res);
                    return;
                }

                updatePolicyParamsWithJsonValues(req, asyncResp, policyParams);

                if (asyncResp->res.result() != boost::beast::http::status::ok)
                {
                    BMCWEB_LOG_ERROR(
                        "Paremters update has failed for policy: {}",
                        policyObjectPath);
                    return;
                }

                crow::connections::systemBus->async_method_call(
                    [asyncResp, req, policyObjectPath,
                     policyName](const boost::system::error_code ec2) {
                    if (ec2)
                    {
                        BMCWEB_LOG_ERROR(
                            "Update method has failed for policy: {}",
                            policyObjectPath);
                        nmDbus::dbusErrorToBmcwebMessage(asyncResp, req, ec2,
                                                         policyObjectPath);
                        return;
                    }
                    getAttributes(asyncResp, policyObjectPath);
                    getStatistics(asyncResp, policyObjectPath);
                    },
                    kNodeManagerService, policyObjectPath,
                    kPolicyAttributesInterface, "Update", policyParams);
                });
            });
        });

    BMCWEB_ROUTE(
        app, "/redfish/v1/Managers/bmc/Oem/Intel/NodeManager/Policies/<str>/"
             "Actions/Policy.ChangeState")
        .privileges(redfish::privileges::privilegeSetConfigureManager)
        .methods(boost::beast::http::verb::post)(
            [](const crow::Request& req,
               const std::shared_ptr<bmcweb::AsyncResp>& asyncResp,
               const std::string& policyName) {
        getPolicyObjectPath(
            req, asyncResp, policyName,
            [req, asyncResp, policyName](const std::string& policyObjectPath) {
            sdbusplus::asio::getAllProperties(
                *crow::connections::systemBus, kNodeManagerService,
                policyObjectPath, kPolicyAttributesInterface,
                [req, asyncResp, policyObjectPath, policyName](
                    boost::system::error_code ec,
                    const std::vector<
                        std::pair<std::string, dbus::utility::DbusVariantType>>&
                        properties) {
                if (ec)
                {
                    BMCWEB_LOG_ERROR("Cannot get properties for policy: {}",
                                     policyObjectPath);
                    messages::internalError(asyncResp->res);
                    return;
                }

                if (!isHwProtectionPolicy(properties) &&
                    isPolicyReadOnly(properties))
                {
                    BMCWEB_LOG_INFO(
                        "The attempt to modify the object has been denied: {}",
                        policyObjectPath);
                    messages::operationNotAllowed(asyncResp->res);
                    return;
                }
                changeDbusObjectState(req, asyncResp, policyName,
                                      "Policy.ChangeState", policyObjectPath);
                });
            });
        });

    BMCWEB_ROUTE(
        app, "/redfish/v1/Managers/bmc/Oem/Intel/NodeManager/Policies/<str>/"
             "Actions/Policy.ResetStatistics")
        .privileges(redfish::privileges::privilegeSetConfigureManager)
        .methods(boost::beast::http::verb::post)(
            [](const crow::Request& req,
               const std::shared_ptr<bmcweb::AsyncResp>& asyncResp,
               const std::string& policyName) {
        getPolicyObjectPath(
            req, asyncResp, policyName,
            [req, asyncResp, policyName](const std::string& policyObjectPath) {
            BMCWEB_LOG_DEBUG("Proceeding Policy.ResetStatistics on policy: {}",
                             policyName);

            resetStatistics(asyncResp, policyObjectPath);
            return;
            });
        });

    BMCWEB_ROUTE(app, "/redfish/v1/Managers/bmc/Oem/Intel/NodeManager/Policies")
        .privileges(redfish::privileges::privilegeSetConfigureManager)
        .methods(boost::beast::http::verb::post)(
            [](const crow::Request& req,
               const std::shared_ptr<bmcweb::AsyncResp>& asyncResp) {
        uint32_t correctionInMs;
        uint16_t limit;
        std::string statisticsReportingPeriodString;
        std::string policyStorageString;
        std::string powerCorrectionTypeString;
        std::string limitExceptionString;
        uint8_t componentId;
        nlohmann::json trigger;
        uint16_t triggerLimit;
        std::string triggerType;
        std::string domain;
        std::string id;
        nlohmann::json status;
        std::string stateString;

        if (!json_util::readJsonAction(
                req, asyncResp->res, "CorrectionInMs", correctionInMs, "Limit",
                limit, "StatisticsReportingPeriod",
                statisticsReportingPeriodString, "PolicyStorage",
                policyStorageString, "PowerCorrectionType",
                powerCorrectionTypeString, "LimitException",
                limitExceptionString, "ComponentId", componentId, "Trigger",
                trigger, "Domain", domain, "Id", id, "Status", status))
        {
            return;
        }

        if (!json_util::readJson(trigger, asyncResp->res, "TriggerLimit",
                                 triggerLimit, "TriggerType", triggerType))
        {
            return;
        }

        if (!json_util::readJson(status, asyncResp->res, "State", stateString))
        {
            return;
        }

        uint16_t statisticsReportingPeriod = convertTimeString<uint16_t>(
            asyncResp, statisticsReportingPeriodString,
            "StatisticsReportingPeriod");
        int32_t policyStorage = convertStringToEnum<int32_t>(
            asyncResp, policyStorageString, "PolicyStorage", kPolicyStorageMap);
        int32_t powerCorrectionType = convertStringToEnum<int32_t>(
            asyncResp, powerCorrectionTypeString, "PowerCorrectionType",
            kPowerCorrectionTypeMap);
        int32_t limitException =
            convertStringToEnum<int32_t>(asyncResp, limitExceptionString,
                                         "LimitException", kLimitExceptionMap);
        bool state = convertStringToEnum<bool>(asyncResp, stateString, "State",
                                               kPolicyStateMap);

        if (asyncResp->res.result() != boost::beast::http::status::ok)
        {
            return;
        }

        crow::connections::systemBus->async_method_call(
            [req, asyncResp, id,
             state](const boost::system::error_code& ec,
                    const sdbusplus::message::object_path& policyObjectPath) {
            if (ec)
            {
                nmDbus::dbusErrorToBmcwebMessage(asyncResp, req, ec,
                                                 policyObjectPath.str);
                return;
            }
            BMCWEB_LOG_DEBUG("Created new policy: {}", policyObjectPath.str);
            messages::created(asyncResp->res);
            if (state)
            {
                crow::connections::systemBus->async_method_call(
                    [asyncResp](const boost::system::error_code ec2) {
                    if (ec2)
                    {
                        BMCWEB_LOG_DEBUG("DBUS response error {}", ec2);
                        messages::internalError(asyncResp->res);
                        return;
                    }
                    },
                    kNodeManagerService, policyObjectPath,
                    "org.freedesktop.DBus.Properties", "Set",
                    "xyz.openbmc_project.Object.Enable", "Enabled",
                    std::variant<bool>(true));
            }
            getAttributes(asyncResp, policyObjectPath);
            getStatistics(asyncResp, policyObjectPath);
            },
            kNodeManagerService, getDomainDbusPath(domain),
            kPolicyManagerInterface, "CreateWithId", id,
            std::tuple(correctionInMs, limit, statisticsReportingPeriod,
                       policyStorage, powerCorrectionType, limitException,
                       SuspendPeriodsType{}, ThresholdsType{}, componentId,
                       triggerLimit, triggerType));
        });
}
} // namespace redfish
