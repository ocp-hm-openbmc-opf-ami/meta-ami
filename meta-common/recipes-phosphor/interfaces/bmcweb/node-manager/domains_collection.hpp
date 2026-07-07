
/*
// Copyright (c) 2021 Intel Corporation
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

#include "nm_common.hpp"
#include "utils/time_utils.hpp"

#include <app.hpp>
#include <http_request.hpp>
#include <http_response.hpp>
#include <sdbusplus/asio/property.hpp>

#include <string>

namespace redfish
{

constexpr const char* kDomainPath = "/xyz/openbmc_project/NodeManager/Domain/";
constexpr const char* kCapabilitiesInterface =
    "xyz.openbmc_project.NodeManager.Capabilities";
constexpr const char* kDomainAttributesInterface =
    "xyz.openbmc_project.NodeManager.DomainAttributes";

constexpr const char* acTotalPlatformPowerDomainId = "ACTotalPlatformPower";

template <typename T>
static void
    setProperty(const std::shared_ptr<bmcweb::AsyncResp> response,
                const std::string& service, const std::string& path,
                const std::string& interface, const std::string& property,
                T& value,
                const std::shared_ptr<FinalCallback> finalCallback = nullptr)
{
    sdbusplus::asio::setProperty<double>(
        *crow::connections::systemBus, service, path, interface, property,
        std::move(value),
        [response, interface, property, value, path,
         finalCallback](boost::system::error_code ec) {
        BMCWEB_LOG_DEBUG("Updating property {}.{} in {} with value: {}",
                         interface, property, path, value);
        if (ec)
        {
            BMCWEB_LOG_DEBUG("DBus response error: {}", ec);
            messages::propertyValueIncorrect(response->res, property,
                                             std::to_string(value));
            return;
        }
        });
}

inline void setCapabilities(
    const std::shared_ptr<bmcweb::AsyncResp>& response,
    const std::string& domainName, nlohmann::json& capabilitiesCollection,
    const std::shared_ptr<FinalCallback> finalCallback = nullptr)
{
    std::optional<double> capabilitiesMax;
    std::optional<double> capabilitiesMin;
    if (!json_util::readJson(capabilitiesCollection, response->res, "Max",
                             capabilitiesMax, "Min", capabilitiesMin))
    {
        return;
    }

    if (capabilitiesMax)
    {
        setProperty(response, kNodeManagerService, kDomainPath + domainName,
                    kCapabilitiesInterface, "Max", *capabilitiesMax,
                    finalCallback);
    }

    if (capabilitiesMin)
    {
        setProperty(response, kNodeManagerService, kDomainPath + domainName,
                    kCapabilitiesInterface, "Min", *capabilitiesMin,
                    finalCallback);
    }
}

inline void
    setLimitBiases(const std::shared_ptr<bmcweb::AsyncResp>& response,
                   const std::string& domainName,
                   nlohmann::json& limitBiasCollection,
                   const std::shared_ptr<FinalCallback> finalCallback = nullptr)
{
    std::optional<double> absoluteLimitBias;
    std::optional<double> relativeLimitBias;
    if (!json_util::readJson(limitBiasCollection, response->res,
                             "AbsoluteLimitBias", absoluteLimitBias,
                             "RelativeLimitBias", relativeLimitBias))
    {
        return;
    }

    if (absoluteLimitBias)
    {
        setProperty(response, kNodeManagerService, kDomainPath + domainName,
                    kDomainAttributesInterface, "LimitBiasAbsolute",
                    *absoluteLimitBias, finalCallback);
    }

    if (relativeLimitBias)
    {
        setProperty(response, kNodeManagerService, kDomainPath + domainName,
                    kDomainAttributesInterface, "LimitBiasRelative",
                    *relativeLimitBias, finalCallback);
    }
}

static void getComponentCapabilities(
    const std::shared_ptr<bmcweb::AsyncResp>& asyncResp,
    const std::string& dbusPath)
{
    crow::connections::systemBus->async_method_call(
        [asyncResp](
            const boost::system::error_code ec,
            boost::container::flat_map<
                std::string, boost::container::flat_map<std::string, double>>
                capabilities) {
        if (ec)
        {
            BMCWEB_LOG_ERROR("respHandler DBus error: {}", ec.message());
            messages::internalError(asyncResp->res);
            return;
        }
        auto capabilitiesJson = nlohmann::json::array();
        for (const auto& [capName, capValues] : capabilities)
        {
            nlohmann::json capJson;
            capJson["Name"] = capName;
            for (const auto& [valueName, valueVar] : capValues)
            {
                capJson[valueName] = valueVar;
            }
            asyncResp->res.jsonValue["ComponentCapabilities"].push_back(
                capJson);
        }
        },
        kNodeManagerService, dbusPath,
        "xyz.openbmc_project.NodeManager.Capabilities",
        "GetAllLimitsCapabilities");
}

static void getCapabilities(const std::shared_ptr<bmcweb::AsyncResp>& asyncResp,
                            const std::string& dbusPath)
{
    crow::connections::systemBus->async_method_call(
        [asyncResp,
         dbusPath](const boost::system::error_code ec,
                   const boost::container::flat_map<
                       std::string, std::variant<double, uint32_t, uint16_t>>&
                       properties) {
        if (ec)
        {
            BMCWEB_LOG_ERROR("respHandler DBus error: {}", ec.message());
            messages::internalError(asyncResp->res);
            return;
        }
        const double* max = nullptr;
        const double* min = nullptr;
        const uint32_t* maxCorrectionTimeInMs = nullptr;
        const uint32_t* minCorrectionTimeInMs = nullptr;
        const uint16_t* maxStatReportingPeriod = nullptr;
        const uint16_t* minStatReportingPeriod = nullptr;

        for (const auto& [key, value] : properties)
        {
            if ("Max" == key)
            {
                max = std::get_if<double>(&value);
            }
            else if ("Min" == key)
            {
                min = std::get_if<double>(&value);
            }
            else if ("MaxCorrectionTimeInMs" == key)
            {
                maxCorrectionTimeInMs = std::get_if<uint32_t>(&value);
            }
            else if ("MinCorrectionTimeInMs" == key)
            {
                minCorrectionTimeInMs = std::get_if<uint32_t>(&value);
            }
            else if ("MaxStatisticsReportingPeriod" == key)
            {
                maxStatReportingPeriod = std::get_if<uint16_t>(&value);
            }
            else if ("MinStatisticsReportingPeriod" == key)
            {
                minStatReportingPeriod = std::get_if<uint16_t>(&value);
            }
        }

        if (max)
        {
            asyncResp->res.jsonValue["Capabilities"]["Max"] = *max;
        }
        else
        {
            asyncResp->res.jsonValue["Capabilities"]["Max"] = nullptr;
        }
        if (min)
        {
            asyncResp->res.jsonValue["Capabilities"]["Min"] = *min;
        }
        else
        {
            asyncResp->res.jsonValue["Capabilities"]["Min"] = nullptr;
        }

        if (!maxCorrectionTimeInMs || !minCorrectionTimeInMs ||
            !maxStatReportingPeriod || !minStatReportingPeriod)
        {
            BMCWEB_LOG_ERROR("Property type mismatch or property is missing");
            messages::internalError(asyncResp->res);
            return;
        }
        asyncResp->res.jsonValue["Capabilities"]["MaxCorrectionTimeInMs"] =
            *maxCorrectionTimeInMs;
        asyncResp->res.jsonValue["Capabilities"]["MinCorrectionTimeInMs"] =
            *minCorrectionTimeInMs;
        asyncResp->res
            .jsonValue["Capabilities"]["MaxStatisticsReportingPeriod"] =
            time_utils::toDurationString(
                std::chrono::duration_cast<std::chrono::milliseconds>(
                    std::chrono::seconds(*maxStatReportingPeriod)));
        asyncResp->res
            .jsonValue["Capabilities"]["MinStatisticsReportingPeriod"] =
            time_utils::toDurationString(
                std::chrono::duration_cast<std::chrono::milliseconds>(
                    std::chrono::seconds(*minStatReportingPeriod)));
        ;
        },
        kNodeManagerService, dbusPath, "org.freedesktop.DBus.Properties",
        "GetAll", "xyz.openbmc_project.NodeManager.Capabilities");
}

static void
    getDomainTriggers(const std::shared_ptr<bmcweb::AsyncResp>& asyncResp,
                      const std::string& dbusPath)
{
    crow::connections::systemBus->async_method_call(
        [asyncResp](const boost::system::error_code ec,
                    const std::variant<std::vector<std::string>> response) {
        if (ec)
        {
            BMCWEB_LOG_ERROR("respHandler DBus error: {}", ec.message());
            messages::internalError(asyncResp->res);
            return;
        }
        auto* triggers = std::get_if<std::vector<std::string>>(&response);
        if (!triggers)
        {
            BMCWEB_LOG_ERROR("Property type mismatch or property is missing");
            messages::internalError(asyncResp->res);
            return;
        }
        auto triggersJson = nlohmann::json::array();
        for (const auto& value : *triggers)
        {
            triggersJson.push_back(
                {{"@odata.id",
                  "/redfish/v1/Managers/bmc/Oem/Intel/NodeManager/Triggers/" +
                      value}});
        }
        asyncResp->res.jsonValue["SupportedTriggers"] = triggersJson;
        asyncResp->res.jsonValue["SupportedTriggers@odata.count"] =
            triggersJson.size();
        },
        kNodeManagerService, dbusPath, "org.freedesktop.DBus.Properties", "Get",
        "xyz.openbmc_project.NodeManager.DomainAttributes",
        "AvailableTriggers");
}

static void getLimitBias(const std::shared_ptr<bmcweb::AsyncResp>& asyncResp,
                         const std::string& dbusPath)
{
    sdbusplus::asio::getProperty<double>(
        *crow::connections::systemBus, kNodeManagerService, dbusPath,
        "xyz.openbmc_project.NodeManager.DomainAttributes", "LimitBiasAbsolute",
        [asyncResp](boost::system::error_code ec, double limitBiasAbsolute) {
        if (ec)
        {
            BMCWEB_LOG_ERROR("respHandler DBus error: {}", ec.message());
            messages::internalError(asyncResp->res);
            return;
        }
        asyncResp->res.jsonValue["LimitBias"]["AbsoluteLimitBias"] =
            limitBiasAbsolute;
        });

    sdbusplus::asio::getProperty<double>(
        *crow::connections::systemBus, kNodeManagerService, dbusPath,
        "xyz.openbmc_project.NodeManager.DomainAttributes", "LimitBiasRelative",
        [asyncResp](boost::system::error_code ec, double limitBiasRelative) {
        if (ec)
        {
            BMCWEB_LOG_ERROR("respHandler DBus error: {}", ec.message());
            messages::internalError(asyncResp->res);
            return;
        }
        asyncResp->res.jsonValue["LimitBias"]["RelativeLimitBias"] =
            limitBiasRelative;
        });
}

static void
    getLimitingPolicies(const std::shared_ptr<bmcweb::AsyncResp>& asyncResp,
                        const std::string& dbusPath)
{
    crow::connections::systemBus->async_method_call(
        [asyncResp](
            const boost::system::error_code ec,
            const std::vector<sdbusplus::message::object_path>& response) {
        if (ec)
        {
            BMCWEB_LOG_ERROR("respHandler DBus error: {}", ec.message());
            messages::internalError(asyncResp->res);
            return;
        }
        const auto& policiesJson = dbusPoliciesPathsToLinks(response);
        asyncResp->res.jsonValue["LimitingPolicies"] = policiesJson;
        asyncResp->res.jsonValue["LimitingPolicies@odata.count"] =
            policiesJson.size();
        },
        kNodeManagerService, dbusPath,
        "xyz.openbmc_project.NodeManager.PolicyManager", "GetSelectedPolicies");
}

void getDomainObjectPath(const crow::Request& req,
                         const std::shared_ptr<bmcweb::AsyncResp>& asyncResp,
                         const std::string& domainName,
                         std::function<void(const std::string&)> handler)
{
    crow::connections::systemBus->async_method_call(
        [req, asyncResp, domainName,
         handler](const boost::system::error_code ec,
                  const std::vector<std::string>& objects) {
        if (ec)
        {
            BMCWEB_LOG_ERROR("respHandler DBus error: {}", ec.message());
            messages::internalError(asyncResp->res);
        }

        auto domainObjectPath =
            std::find_if(objects.begin(), objects.end(),
                         [&domainName](const std::string& objectPath) {
            std::smatch match;
            std::regex search(getDomainDbusPath(domainName) + "$");
            if (std::regex_search(objectPath, match, search))
            {
                return true;
            }
            return false;
            });

        if (objects.end() == domainObjectPath)
        {
            messages::resourceNotFound(asyncResp->res, "Domains", domainName);
            return;
        }
        std::string domainObjectPathValue = *domainObjectPath;
        handler(domainObjectPathValue);
        },
        kObjectMapperService, kObjectMapperObjectPath, kObjectMapperService,
        "GetSubTreePaths", kNodeManagerObjectPath, 0,
        std::vector<const char*>{kDomainAttributesInterface});
}

static void getDomain(const std::shared_ptr<bmcweb::AsyncResp>& asyncResp,
                      const std::string& domainName,
                      const std::string& domainDbusPath)
{
    getCapabilities(asyncResp, domainDbusPath);
    getComponentCapabilities(asyncResp, domainDbusPath);
    getEnabled(asyncResp, domainDbusPath);
    getStatistics(asyncResp, domainDbusPath);
    // in case of domain O (AcTotalPlatformPower) append stats from the main
    // node
    if (domainName == acTotalPlatformPowerDomainId)
    {
        getStatistics(asyncResp, kNodeManagerObjectPath);
    }
    getDomainTriggers(asyncResp, domainDbusPath);
    getLimitBias(asyncResp, domainDbusPath);
    getLimitingPolicies(asyncResp, domainDbusPath);

    auto addPolicies =
        [asyncResp, domainName](
            const boost::system::error_code& ec,
            const std::vector<sdbusplus::message::object_path>& paths) {
        if (ec)
        {
            BMCWEB_LOG_ERROR("respHandler DBus error: {}", ec.message());
            messages::internalError(asyncResp->res);
            return;
        }
        nlohmann::json& members = asyncResp->res.jsonValue["Links"]["Policies"];
        members = dbusPoliciesPathsToLinks(paths);
        asyncResp->res.jsonValue["Links"]["Policies@odata.count"] =
            members.size();
    };

    asyncFindPolicies(addPolicies,
                      [domainName](const nmDbus::DBusPropertiesMap& propMap) {
        return createAttributePredicate("DomainId", domainName)(propMap);
    });

    asyncResp->res.jsonValue = {
        {"@odata.type", "#NmDomain.v1_4_0.NmDomain"},
        {"@odata.id",
         "/redfish/v1/Managers/bmc/Oem/Intel/NodeManager/Domains/" +
             domainName},
        {"Id", domainName},
        {"Name", domainName},
        {"Actions",
         {{"#NmDomain.ChangeState",
           {{"State@Redfish.AllowableValues", {"Enabled", "Disabled"}},
            {"target",
             "/redfish/v1/Managers/bmc/Oem/Intel/NodeManager/Domains/" +
                 domainName + "/Actions/Domain.ChangeState"}}},
          {"#NmDomain.ResetStatistics",
           {{"target",
             "/redfish/v1/Managers/bmc/Oem/Intel/NodeManager/Domains/" +
                 domainName + "/Actions/Domain.ResetStatistics"}}}}},
    };
}

inline void requestRoutesNodeManagerDomains(App& app)
{
    BMCWEB_ROUTE(app, "/redfish/v1/Managers/bmc/Oem/Intel/NodeManager/Domains/")
        .privileges(redfish::privileges::privilegeSetLogin)
        .methods(boost::beast::http::verb::get)(
            [](const crow::Request&,
               const std::shared_ptr<bmcweb::AsyncResp>& asyncResp) {
        asyncResp->res.jsonValue = {
            {"@odata.type", "#NmDomainCollection.NmDomainCollection"},
            {"@odata.id",
             "/redfish/v1/Managers/bmc/Oem/Intel/NodeManager/Domains"},
            {"Name", "NM Domains Collection"},
        };

        constexpr std::array<std::string_view, 1> interface {
            "xyz.openbmc_project.NodeManager.DomainAttributes"
        };

        collection_util::getCollectionMembers(
            asyncResp,
            boost::urls::url(
                "/redfish/v1/Managers/bmc/Oem/Intel/NodeManager/Domains"),
            interface, "/xyz/openbmc_project/NodeManager");
        });

    BMCWEB_ROUTE(
        app, "/redfish/v1/Managers/bmc/Oem/Intel/NodeManager/Domains/<str>/")
        .privileges(redfish::privileges::privilegeSetLogin)
        .methods(boost::beast::http::verb::get)(
            [](const crow::Request& req,
               const std::shared_ptr<bmcweb::AsyncResp>& asyncResp,
               const std::string& domainName) {
        getDomainObjectPath(
            req, asyncResp, domainName,
            [asyncResp, domainName](const std::string& domainObjectPath) {
            getDomain(asyncResp, domainName, domainObjectPath);
            });
        });

    BMCWEB_ROUTE(app,
                 "/redfish/v1/Managers/bmc/Oem/Intel/NodeManager/Domains/<str>")
        .privileges(redfish::privileges::privilegeSetConfigureManager)
        .methods(boost::beast::http::verb::patch)(
            [](const crow::Request& req,
               const std::shared_ptr<bmcweb::AsyncResp>& asyncResp,
               const std::string& domainName) {
        getDomainObjectPath(
            req, asyncResp, domainName,
            [req, asyncResp, domainName](const std::string& domainObjectPath) {
            std::optional<nlohmann::json> capabilitiesCollection;
            std::optional<nlohmann::json> limitBiasCollection;
            if (!json_util::readJsonAction(req, asyncResp->res, "Capabilities",
                                           capabilitiesCollection, "LimitBias",
                                           limitBiasCollection))
            {
                return;
            }

            std::shared_ptr<FinalCallback> finalCallback =
                std::make_shared<FinalCallback>(
                    [asyncResp, domainName, domainObjectPath]() {
                if (asyncResp->res.result() == boost::beast::http::status::ok)
                {
                    getDomain(asyncResp, domainName, domainObjectPath);
                }
                });

            if (capabilitiesCollection)
            {
                setCapabilities(asyncResp, domainName, *capabilitiesCollection,
                                finalCallback);
            }

            if (limitBiasCollection)
            {
                setLimitBiases(asyncResp, domainName, *limitBiasCollection,
                               finalCallback);
            }
            });
        });

    BMCWEB_ROUTE(app,
                 "/redfish/v1/Managers/bmc/Oem/Intel/NodeManager/Domains/<str>/"
                 "Actions/Domain.ResetStatistics/")
        .privileges(redfish::privileges::privilegeSetConfigureManager)
        .methods(boost::beast::http::verb::post)(
            [](const crow::Request& req,
               const std::shared_ptr<bmcweb::AsyncResp>& asyncResp,
               const std::string& domainName) {
        BMCWEB_LOG_DEBUG("Domain.ResetStatistics");
        getDomainObjectPath(
            req, asyncResp, domainName,
            [req, asyncResp, domainName](const std::string& domainObjectPath) {
            resetStatistics(asyncResp, domainObjectPath);

            // in case of domain O (AcTotalPlatformPower) resets also stats
            // from the main node
            if (domainName == acTotalPlatformPowerDomainId)
            {
                resetStatistics(asyncResp, kNodeManagerObjectPath);
            }
            });
        });

    BMCWEB_ROUTE(app,
                 "/redfish/v1/Managers/bmc/Oem/Intel/NodeManager/Domains/<str>/"
                 "Actions/Domain.ChangeState/")
        .privileges(redfish::privileges::privilegeSetConfigureManager)
        .methods(boost::beast::http::verb::post)(
            [](const crow::Request& req,
               const std::shared_ptr<bmcweb::AsyncResp>& asyncResp,
               const std::string& domainName) {
        getDomainObjectPath(
            req, asyncResp, domainName,
            [req, asyncResp, domainName](const std::string& domainObjectPath) {
            changeDbusObjectState(req, asyncResp, domainName,
                                  "Domain.ChangeState", domainObjectPath);
            return;
            });
        return;
        });
}

} // namespace redfish
