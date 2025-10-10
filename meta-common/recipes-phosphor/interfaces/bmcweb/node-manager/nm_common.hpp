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
#include "utils/time_utils.hpp"

#include <systemd/sd-bus.h>

#include <app.hpp>
#include <http_request.hpp>
#include <http_response.hpp>

#include <string>
#include <type_traits>

namespace redfish
{

constexpr const char* kNodeManagerService = "xyz.openbmc_project.NodeManager";
constexpr const char* kNodeManagerObjectPath =
    "/xyz/openbmc_project/NodeManager";
constexpr const char* kObjectMapperService = "xyz.openbmc_project.ObjectMapper";
constexpr const char* kObjectMapperObjectPath =
    "/xyz/openbmc_project/object_mapper";

constexpr const int32_t kPolicyOwnerBmc = 0;

class FinalCallback
{
  private:
    const std::function<void(void)> runCompleteCallback;

  public:
    FinalCallback(const std::function<void(void)> callback) :
        runCompleteCallback(callback){};

    ~FinalCallback()
    {
        if (runCompleteCallback != nullptr)
        {
            runCompleteCallback();
        }
    }
};

template <typename T>
std::optional<T> getPropertyValue(
    const std::vector<std::pair<std::string, dbus::utility::DbusVariantType>>&
        properties,
    const std::string& name)
{
    auto property = std::find_if(properties.begin(), properties.end(),
                                 [&name](auto element) {
        if (name == element.first)
        {
            return true;
        }
        return false;
    });

    if (properties.end() != property)
    {
        if (const auto* value = std::get_if<T>(&(property->second)))
        {
            return *value;
        }
    }

    return std::nullopt;
}

template <typename T>
T convertStringToEnum(const std::shared_ptr<bmcweb::AsyncResp>& asyncResp,
                      const std::string& string, const std::string& name,
                      const boost::container::flat_map<T, std::string>& map)
{
    auto property = std::find_if(map.begin(), map.end(),
                                 [&string](auto element) {
        if (string == element.second)
        {
            return true;
        }
        return false;
    });

    if (map.end() != property)
    {
        return property->first;
    }

    messages::propertyMissing(asyncResp->res, name);
    return T{0};
}

template <typename T>
T convertTimeString(const std::shared_ptr<bmcweb::AsyncResp>& asyncResp,
                    const std::string& string, const std::string& name)
{
    if (auto value = time_utils::fromDurationString(string))
    {
        auto sec =
            std::chrono::duration_cast<std::chrono::seconds>(*value).count();
        if (sec <= std::numeric_limits<T>::max())
        {
            return static_cast<T>(sec);
        }
    }
    messages::propertyValueIncorrect(asyncResp->res, name, string);
    return T{0};
}

namespace nmDbus
{
using DbusVariantType =
    std::variant<bool, std::string, int32_t, double, uint32_t, uint16_t,
                 std::vector<uint8_t>, uint8_t>;

using DBusPropertiesMap =
    boost::container::flat_map<std::string, DbusVariantType>;
using DBusInterfacesMap =
    boost::container::flat_map<std::string, DBusPropertiesMap>;
using ManagedObjectType =
    std::vector<std::pair<sdbusplus::message::object_path, DBusInterfacesMap>>;

// Bmcweb NM completion codes specified by the Intel OpenBMC Node Manager
// External Interface Specification
//
enum class ErrorCodes : int
{
    CorrectionTimeOutOfRange = 1000,
    InvalidPolicyId,
    PowerLimitOutOfRange,
    StatRepPeriodOutOfRange,
    InvalidPolicyStorage,
    InvalidPowerCorrectionType,
    InvalidLimitException,
    InvalidComponentId,
    ReadingSourceUnavailable,
    TriggerValueOutOfRange,
    UnsupportedPolicyTriggerType,
    OperationNotPermitted,
    CmdNotSupported,
    PoliciesCannotBeCreated,
    PolicyIdAlreadyExists,
};

static constexpr sd_bus_error_map kNodeManagerDBusErrors[] = {
    SD_BUS_ERROR_MAP(
        "xyz.openbmc_project.NodeManager.Error.CorrectionTimeOutOfRange",
        std::underlying_type_t<ErrorCodes>(
            ErrorCodes::CorrectionTimeOutOfRange)),
    SD_BUS_ERROR_MAP(
        "xyz.openbmc_project.NodeManager.Error.InvalidPolicyId",
        std::underlying_type_t<ErrorCodes>(ErrorCodes::InvalidPolicyId)),
    SD_BUS_ERROR_MAP(
        "xyz.openbmc_project.NodeManager.Error.PowerLimitOutOfRange",
        std::underlying_type_t<ErrorCodes>(ErrorCodes::PowerLimitOutOfRange)),
    SD_BUS_ERROR_MAP("xyz.openbmc_project.NodeManager.Error."
                     "StatRepPeriodOutOfRange",
                     std::underlying_type_t<ErrorCodes>(
                         ErrorCodes::StatRepPeriodOutOfRange)),
    SD_BUS_ERROR_MAP(
        "xyz.openbmc_project.NodeManager.Error.InvalidPolicyStorage",
        std::underlying_type_t<ErrorCodes>(ErrorCodes::InvalidPolicyStorage)),
    SD_BUS_ERROR_MAP(
        "xyz.openbmc_project.NodeManager.Error.InvalidPowerCorrectionType",
        std::underlying_type_t<ErrorCodes>(
            ErrorCodes::InvalidPowerCorrectionType)),
    SD_BUS_ERROR_MAP(
        "xyz.openbmc_project.NodeManager.Error.InvalidLimitException",
        std::underlying_type_t<ErrorCodes>(ErrorCodes::InvalidLimitException)),
    SD_BUS_ERROR_MAP(
        "xyz.openbmc_project.NodeManager.Error.InvalidComponentId",
        std::underlying_type_t<ErrorCodes>(ErrorCodes::InvalidComponentId)),
    SD_BUS_ERROR_MAP(
        "xyz.openbmc_project.NodeManager.Error.ReadingSourceUnavailable",
        std::underlying_type_t<ErrorCodes>(
            ErrorCodes::ReadingSourceUnavailable)),
    SD_BUS_ERROR_MAP(
        "xyz.openbmc_project.NodeManager.Error.TriggerValueOutOfRange",
        std::underlying_type_t<ErrorCodes>(ErrorCodes::TriggerValueOutOfRange)),
    SD_BUS_ERROR_MAP("xyz.openbmc_project.NodeManager.Error."
                     "UnsupportedPolicyTriggerType",
                     std::underlying_type_t<ErrorCodes>(
                         ErrorCodes::UnsupportedPolicyTriggerType)),
    SD_BUS_ERROR_MAP(
        "xyz.openbmc_project.NodeManager.Error."
        "OperationNotPermitted",
        std::underlying_type_t<ErrorCodes>(ErrorCodes::OperationNotPermitted)),
    SD_BUS_ERROR_MAP(
        "xyz.openbmc_project.NodeManager.Error."
        "CmdNotSupported",
        std::underlying_type_t<ErrorCodes>(ErrorCodes::CmdNotSupported)),
    SD_BUS_ERROR_MAP("xyz.openbmc_project.NodeManager.Error."
                     "PoliciesCannotBeCreated",
                     std::underlying_type_t<ErrorCodes>(
                         ErrorCodes::PoliciesCannotBeCreated)),
    SD_BUS_ERROR_MAP(
        "xyz.openbmc_project.NodeManager.Error."
        "PolicyIdAlreadyExists",
        std::underlying_type_t<ErrorCodes>(ErrorCodes::PolicyIdAlreadyExists)),
    SD_BUS_ERROR_MAP_END};

static std::unordered_map<ErrorCodes, std::string> kErrorCodeToPropertyName = {
    {ErrorCodes::CorrectionTimeOutOfRange, "CorrectionInMs"},
    {ErrorCodes::InvalidPolicyId, "Id"},
    {ErrorCodes::PowerLimitOutOfRange, "Limit"},
    {ErrorCodes::StatRepPeriodOutOfRange, "StatisticsReportingPeriod"},
    {ErrorCodes::InvalidPolicyStorage, "PolicyStorage"},
    {ErrorCodes::InvalidPowerCorrectionType, "PowerCorrectionType"},
    {ErrorCodes::InvalidLimitException, "LimitException"},
    {ErrorCodes::InvalidComponentId, "ComponentId"},
    {ErrorCodes::TriggerValueOutOfRange, "TriggerLimit"},
    {ErrorCodes::UnsupportedPolicyTriggerType, "TriggerType"},
};

void dbusErrorToBmcwebMessage(
    const std::shared_ptr<bmcweb::AsyncResp>& asyncResp,
    const crow::Request& req, const boost::system::error_code& ec,
    const std::optional<std::string>& objectPath)
{
    BMCWEB_LOG_DEBUG("DBUS response error: {}", ec.message());

    auto it =
        kErrorCodeToPropertyName.find(static_cast<ErrorCodes>(ec.value()));

    nlohmann::json jsonRequest;
    if (!json_util::processJsonFromRequest(asyncResp->res, req, jsonRequest))
    {
        return;
    }

    switch (static_cast<ErrorCodes>(ec.value()))
    {
        case ErrorCodes::CorrectionTimeOutOfRange:
        case ErrorCodes::PowerLimitOutOfRange:
        case ErrorCodes::StatRepPeriodOutOfRange:
        case ErrorCodes::InvalidPolicyId:
        case ErrorCodes::InvalidPolicyStorage:
        case ErrorCodes::InvalidPowerCorrectionType:
        case ErrorCodes::InvalidLimitException:
        case ErrorCodes::InvalidComponentId:
        {
            if (it != kErrorCodeToPropertyName.end())
            {
                messages::propertyValueIncorrect(
                    asyncResp->res, it->second, jsonRequest[it->second].dump());
                return;
            }
            break;
        }
        case ErrorCodes::UnsupportedPolicyTriggerType:
        case ErrorCodes::TriggerValueOutOfRange:
        {
            if (it != kErrorCodeToPropertyName.end())
            {
                messages::propertyValueIncorrect(
                    asyncResp->res, it->second,
                    jsonRequest["Trigger"][it->second].dump());
                return;
            }
            break;
        }
        case ErrorCodes::OperationNotPermitted:
        {
            messages::queryNotSupportedOnResource(asyncResp->res);
            return;
        }
        case ErrorCodes::ReadingSourceUnavailable:
        case ErrorCodes::CmdNotSupported:
        {
            messages::operationFailed(asyncResp->res);
            return;
        }
        case ErrorCodes::PolicyIdAlreadyExists:
        case ErrorCodes::PoliciesCannotBeCreated:
        {
            if (objectPath.has_value())
            {
                messages::resourceCreationConflict(
                    asyncResp->res, boost::urls::url_view{objectPath.value()});
                asyncResp->res.result(boost::beast::http::status::conflict);
            }
            else
            {
                BMCWEB_LOG_ERROR("Policy object path is empty");
                messages::internalError(asyncResp->res);
            }
            return;
        }
        default:
            break;
    }
    messages::internalError(asyncResp->res);
}

}; // namespace nmDbus

using PolicyAttributesPredicate =
    std::function<bool(const nmDbus::DBusPropertiesMap&)>;
using FindPoliciesCallback =
    std::function<void(const boost::system::error_code&,
                       const std::vector<sdbusplus::message::object_path>&)>;

static std::string getDomainDbusPath(const std::string& domainName)
{
    return "/xyz/openbmc_project/NodeManager/Domain/" + domainName;
}

/**
 * @brief Returns PolicyAttributesPredicate that will verify if attribute named
 * 'attributeName' equals expectedValue
 *
 * @tparam T
 * @param attributeName
 * @param expectedValue
 * @return PolicyAttributesPredicate
 */
template <class T>
static PolicyAttributesPredicate
    createAttributePredicate(const std::string& attributeName,
                             const T& expectedValue)
{
    return [attributeName,
            expectedValue](const nmDbus::DBusPropertiesMap& propMap) {
        const auto& it = propMap.find(attributeName);
        if (it != propMap.cend())
        {
            const auto varValue = it->second;
            const auto value = std::get_if<T>(&varValue);
            if (value && *value == expectedValue)
            {
                return true;
            }
        }
        return false;
    };
}

static void asyncFindPolicies(FindPoliciesCallback callback,
                              PolicyAttributesPredicate predicate =
                                  createAttributePredicate("Owner",
                                                           kPolicyOwnerBmc))
{
    crow::connections::systemBus->async_method_call(
        [callback, predicate](const boost::system::error_code& ec,
                              nmDbus::ManagedObjectType& managedObj) {
        std::vector<sdbusplus::message::object_path> ret;
        if (ec)
        {
            callback(ec, ret);
            return;
        }
        for (auto& [path, ifMap] : managedObj)
        {
            for (auto& [ifName, propMap] : ifMap)
            {
                if (ifName !=
                    "xyz.openbmc_project.NodeManager.PolicyAttributes")
                {
                    continue;
                }
                if (predicate && !predicate(propMap))
                {
                    BMCWEB_LOG_DEBUG("Policy filtered: {}", path.str);
                    continue;
                }
                ret.push_back(path);
            }
        }
        callback(ec, ret);
        },
        kNodeManagerService, "/xyz/openbmc_project/NodeManager",
        "org.freedesktop.DBus.ObjectManager", "GetManagedObjects");
}

[[maybe_unused]] static void
    getEnabled(const std::shared_ptr<bmcweb::AsyncResp>& asyncResp,
               const std::string& dbusPath)
{
    crow::connections::systemBus->async_method_call(
        [asyncResp](
            const boost::system::error_code ec,
            const boost::container::flat_map<std::string, std::variant<bool>>&
                response) {
        if (ec)
        {
            BMCWEB_LOG_ERROR("respHandler DBus error: {}", ec.message());
            messages::internalError(asyncResp->res);
            return;
        }

        const bool* enabled = nullptr;
        for (const auto& [key, value] : response)
        {
            if ("Enabled" == key)
            {
                enabled = std::get_if<bool>(&value);
            }
        }

        if (!enabled)
        {
            BMCWEB_LOG_ERROR("Property type mismatch or property is missing");
            messages::internalError(asyncResp->res);
            return;
        }
        asyncResp->res.jsonValue["Status"]["State"] = (*enabled ? "Enabled"
                                                                : "Disabled");
        },
        kNodeManagerService, dbusPath, "org.freedesktop.DBus.Properties",
        "GetAll", "xyz.openbmc_project.Object.Enable");
}

static void getStatistics(const std::shared_ptr<bmcweb::AsyncResp>& asyncResp,
                          const std::string& dbusPath)
{
    crow::connections::systemBus->async_method_call(
        [asyncResp](
            const boost::system::error_code ec,
            const boost::container::flat_map<
                std::string,
                boost::container::flat_map<
                    std::string,
                    std::variant<double, uint32_t, uint64_t, bool>>>& stats) {
        if (ec)
        {
            BMCWEB_LOG_ERROR("respHandler DBus error: {}", ec.message());
            messages::internalError(asyncResp->res);
            return;
        }
        if (!asyncResp->res.jsonValue.contains("Statistics"))
        {
            asyncResp->res.jsonValue["Statistics"] = nlohmann::json::array();
        }
        auto& statisticsJson = asyncResp->res.jsonValue["Statistics"];
        for (const auto& [statName, statsMap] : stats)
        {
            nlohmann::json statJson;
            statJson["Name"] = statName;
            for (const auto& [valueName, valueVar] : statsMap)
            {
                std::visit(
                    [&statJson, &valueName](auto& val) {
                    if (valueName == "StatisticsReportingPeriod")
                    {
                        statJson["AveragingInterval"] =
                            time_utils::toDurationString(
                                std::chrono::duration_cast<
                                    std::chrono::milliseconds>(
                                    std::chrono::seconds(
                                        static_cast<uint32_t>(val))));
                    }
                    else
                    {
                        statJson[valueName] = val;
                    }
                    },
                    valueVar);
            }
            statisticsJson.push_back(statJson);
        }
        },
        kNodeManagerService, dbusPath,
        "xyz.openbmc_project.NodeManager.Statistics", "GetStatistics");
}

static void resetStatistics(const std::shared_ptr<bmcweb::AsyncResp>& asyncResp,
                            const std::string& dbusPath)
{
    crow::connections::systemBus->async_method_call(
        [asyncResp](const boost::system::error_code ec) {
        if (ec)
        {
            BMCWEB_LOG_ERROR("respHandler DBus error: {}", ec.message());
            messages::internalError(asyncResp->res);
            return;
        }
        asyncResp->res.result(boost::beast::http::status::no_content);
        },
        kNodeManagerService, dbusPath,
        "xyz.openbmc_project.NodeManager.Statistics", "ResetStatistics");
}

template <typename T, typename F>
void parsePropertyToResponse(
    const std::shared_ptr<bmcweb::AsyncResp>& response,
    const std::vector<std::pair<std::string, dbus::utility::DbusVariantType>>&
        properties,
    const std::string& name, F&& process)
{
    std::optional<T> value = getPropertyValue<T>(properties, name);
    if (value)
    {
        process(*value);
        return;
    }

    messages::internalError(response->res);
}

template <typename T>
void parsePropertyToResponse(
    const std::shared_ptr<bmcweb::AsyncResp>& response,
    const std::vector<std::pair<std::string, dbus::utility::DbusVariantType>>&
        properties,
    const std::string& name)
{
    std::optional<T> value = getPropertyValue<T>(properties, name);
    if (value)
    {
        response->res.jsonValue[name] = *value;
        return;
    }

    messages::internalError(response->res);
}

template <typename T>
void parsePropertyToResponse(
    const std::shared_ptr<bmcweb::AsyncResp>& response,
    const std::vector<std::pair<std::string, dbus::utility::DbusVariantType>>&
        properties,
    const std::string& name,
    const boost::container::flat_map<T, std::string>& namesMap)
{
    std::optional<T> value = getPropertyValue<T>(properties, name);
    if (value)
    {
        auto it = namesMap.find(*value);
        if (it != namesMap.end())
        {
            response->res.jsonValue[name] = it->second;
            return;
        }
    }

    messages::internalError(response->res);
}

template <typename T, typename F>
void parsePropertyToResponse(
    const std::shared_ptr<bmcweb::AsyncResp>& response,
    const std::vector<std::pair<std::string, dbus::utility::DbusVariantType>>&
        properties,
    const std::string& name,
    const boost::container::flat_map<T, std::string>& namesMap, F&& process)
{
    std::optional<T> value = getPropertyValue<T>(properties, name);
    if (value)
    {
        auto it = namesMap.find(*value);
        if (it != namesMap.end())
        {
            process(it->second);
            return;
        }
    }

    messages::internalError(response->res);
}

void changeDbusObjectState(const crow::Request& req,
                           const std::shared_ptr<bmcweb::AsyncResp>& asyncResp,
                           const std::string& objectName,
                           const std::string& actionName,
                           const std::string& objectPath)
{
    BMCWEB_LOG_DEBUG("{}", actionName);
    std::string state;
    bool dbusState;
    if (!json_util::readJsonAction(req, asyncResp->res, "State", state))
    {
        messages::actionParameterMissing(asyncResp->res, actionName, "State");
        return;
    }

    if (state == "Enabled")
    {
        dbusState = true;
    }
    else if (state == "Disabled")
    {
        dbusState = false;
    }
    else
    {
        messages::actionParameterValueFormatError(asyncResp->res, state,
                                                  "State", actionName);
        return;
    }

    BMCWEB_LOG_DEBUG("Proceeding {} with state: {}on: {}", actionName, state,
                     objectName);

    crow::connections::systemBus->async_method_call(
        [asyncResp, objectPath,
         actionName](const boost::system::error_code ec) {
        if (ec)
        {
            BMCWEB_LOG_DEBUG("DBUS response error {}", ec);
            if (static_cast<nmDbus::ErrorCodes>(ec.value()) ==
                nmDbus::ErrorCodes::OperationNotPermitted)
            {
                messages::queryNotSupportedOnResource(asyncResp->res);
            }
            else
            {
                messages::internalError(asyncResp->res);
            }
            return;
        }
        BMCWEB_LOG_DEBUG("{} done.", actionName);
        asyncResp->res.result(boost::beast::http::status::no_content);
        },
        kNodeManagerService, objectPath, "org.freedesktop.DBus.Properties",
        "Set", "xyz.openbmc_project.Object.Enable", "Enabled",
        std::variant<bool>(dbusState));
    return;
}

static nlohmann::json dbusPoliciesPathsToLinks(
    const std::vector<sdbusplus::message::object_path>& dbusPaths)
{
    auto links = nlohmann::json::array();
    for (const auto& path : dbusPaths)
    {
        const std::string& policyId = path.filename();
        if (policyId.empty())
        {
            BMCWEB_LOG_DEBUG("Ignoring policy with invalid ID: {}", path.str);
            continue;
        }
        const std::string& basePath =
            "/redfish/v1/Managers/bmc/Oem/Intel/NodeManager/Policies/";
        links.push_back({{"@odata.id", basePath + policyId}});
    };
    return links;
}

} // namespace redfish
