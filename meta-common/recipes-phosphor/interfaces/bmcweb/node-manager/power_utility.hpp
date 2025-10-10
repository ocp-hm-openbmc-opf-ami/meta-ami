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

#include "nm_common.hpp"
#include "policies_collection.hpp"

#include <sdbusplus/asio/property.hpp>
#include <sdbusplus/unpack_properties.hpp>

#include <chrono>
#include <type_traits>
#include <variant>

namespace redfish
{
namespace nm
{
constexpr const char* dmtfPowerPolicyId = "DmtfPower";
constexpr size_t powerRootNode = 0;
constexpr size_t tempNode = 1;
constexpr const char* kTriggerType = "AlwaysOn";
constexpr const char* cpuDomainId = "CPUSubsystem";
constexpr const char* memoryDomainId = "MemorySubsystem";
constexpr const char* pcieDomainId = "PCIe";
constexpr const char* dcTotalPowerDomainId = "DCTotalPlatformPower";

using PolicyId = std::string;
using DomainId = std::string;
using DeviceIndex = uint8_t;
constexpr const DeviceIndex allDevices = 255;

using SuspendPeriods = std::vector<
    std::map<std::string, std::variant<std::vector<std::string>, std::string>>>;
using Thresholds = std::map<std::string, std::vector<uint16_t>>;

static std::string
    selectNmService(const dbus::utility::MapperGetObject& getObjectType)
{
    if (getObjectType.empty())
    {
        return "";
    }
    std::string preferedServiceName = "xyz.openbmc_project.NodeManager";
    for (auto service : getObjectType)
    {
        if (service.first.compare(preferedServiceName) == 0)
        {
            return preferedServiceName;
        }
    }
    return getObjectType.begin()->first;
}

static const std::vector<std::pair<std::string, int32_t>>
    limitExceptionMapping = {
        {"NoAction", 0}, {"HardPowerOff", 1}, {"LogEventOnly", 2}, {"Oem", 3}};

static const std::vector<std::pair<std::string, int32_t>>
    powerLimitStorageMapping = {{"Persistent", 0}, {"Volatile", 1}};

static const std::string nmPath(const DomainId& domainId)
{
    return "/xyz/openbmc_project/NodeManager/Domain/" + domainId;
}

static const std::string nmPath(const DomainId& domainId, const PolicyId& pId)
{
    return nmPath(domainId) + "/Policy/" + pId;
}

static std::string nmPolicyName(const std::string& type,
                                const DeviceIndex& deviceIndex)
{
    return dmtfPowerPolicyId + std::string{"_"} + type +
           std::to_string(deviceIndex);
}

static std::string nmPolicyName(const std::string& type)
{
    std::string policyName{dmtfPowerPolicyId};

    if (type != "0")
    {
        policyName += std::string{"_"} + type;
    }
    return policyName;
}

template <typename F>
static void enablePolicy(const std::string& nmServiceName,
                         const DomainId& domainId, const PolicyId& policyId,
                         F&& errorHandler)
{
    BMCWEB_LOG_DEBUG("enablePolicy");
    sdbusplus::asio::setProperty(
        *crow::connections::systemBus, nmServiceName,
        nmPath(domainId, policyId), "xyz.openbmc_project.Object.Enable",
        "Enabled", true,
        [domainId, errorHandler, policyId](boost::system::error_code ec) {
        BMCWEB_LOG_DEBUG("{} : Set Enable->Enabled: {}[{}]",
                         nmPath(domainId, policyId), ec.message(), ec.value());
        if (ec)
        {
            errorHandler(ec);
            return;
        }
        });
}

static void updatePolicyToDefaults(
    const std::shared_ptr<SensorsAsyncResp>& sensorAsyncResp,
    const DomainId& domainId, const PolicyId& policyId,
    const std::string& nmServiceName, const DeviceIndex deviceIndex)
{
    BMCWEB_LOG_DEBUG("updatePolicyToDefaults");
    crow::connections::systemBus->async_method_call(
        [domainId, policyId, sensorAsyncResp](boost::system::error_code ec) {
        BMCWEB_LOG_DEBUG("{} : updatePolicyToDefaults->Update: {}[{}]",
                         nmPath(domainId, policyId), ec.message(), ec.value());
        },
        nmServiceName, nmPath(domainId, policyId), kPolicyAttributesInterface,
        "Update",
        std::make_tuple(uint32_t{4000}, uint16_t{0}, uint16_t{1}, int32_t{1},
                        int32_t{2}, int32_t{0}, SuspendPeriods{}, Thresholds{},
                        uint8_t{deviceIndex}, uint16_t{0}, kTriggerType));
    BMCWEB_LOG_DEBUG("disablePolicy");
    sdbusplus::asio::setProperty(
        *crow::connections::systemBus, nmServiceName,
        nmPath(domainId, policyId), "xyz.openbmc_project.Object.Enable",
        "Enabled", false,
        [domainId, sensorAsyncResp, policyId](boost::system::error_code ec) {
        BMCWEB_LOG_DEBUG("{} : Set Enable->Disabled: {}[{}]",
                         nmPath(domainId, policyId), ec.message(), ec.value());
        });
    return;
}

static std::optional<int32_t> limitExceptionToInt(const std::string& value)
{
    for (const auto& [redfishValue, nodeManagerValue] : limitExceptionMapping)
    {
        if (redfishValue == value)
        {
            return nodeManagerValue;
        }
    }
    return std::nullopt;
}

static std::optional<std::string> limitExceptionToStr(int32_t value)
{
    for (const auto& [redfishValue, nodeManagerValue] : limitExceptionMapping)
    {
        if (nodeManagerValue == value)
        {
            return redfishValue;
        }
    }
    return std::nullopt;
}

static std::optional<int32_t> powerLimitStorageToInt(const std::string& value)
{
    for (const auto& [redfishValue, nodeManagerValue] :
         powerLimitStorageMapping)
    {
        if (redfishValue == value)
        {
            return nodeManagerValue;
        }
    }
    return std::nullopt;
}

static std::optional<std::string> powerLimitStorageToStr(int32_t value)
{
    for (const auto& [redfishValue, nodeManagerValue] :
         powerLimitStorageMapping)
    {
        if (nodeManagerValue == value)
        {
            return redfishValue;
        }
    }
    return std::nullopt;
}

static void
    logException(const std::shared_ptr<SensorsAsyncResp>& sensorAsyncResp,
                 const std::string& message)
{
    BMCWEB_LOG_DEBUG("{}", message);
    messages::internalError(sensorAsyncResp->asyncResp->res);
}

template <class T>
static auto handleSetPropertyError(
    const std::shared_ptr<SensorsAsyncResp>& sensorAsyncResp,
    const std::string& name, T value)
{
    return [sensorAsyncResp, name, value](boost::system::error_code) {
        messages::propertyValueIncorrect(sensorAsyncResp->asyncResp->res, name,
                                         std::to_string(value));
    };
}

static void patchPowerPowerControlPowerLimitCorrectionInMs(
    const std::shared_ptr<SensorsAsyncResp>& sensorAsyncResp,
    const DomainId& domainId, const PolicyId& policyId,
    const std::string& nmServiceName, uint32_t correctionInMs)
{
    BMCWEB_LOG_DEBUG("patchPowerPowerControlPowerLimitCorrectionInMs");
    auto handleError = handleSetPropertyError(sensorAsyncResp, "CorrectionInMs",
                                              correctionInMs);

    auto correctionTime = correctionInMs;
    sdbusplus::asio::setProperty<uint32_t>(
        *crow::connections::systemBus, nmServiceName,
        nmPath(domainId, policyId), kPolicyAttributesInterface,
        "CorrectionInMs", std::move(correctionTime),
        [domainId, policyId, handleError, sensorAsyncResp,
         nmServiceName](boost::system::error_code ec) {
        BMCWEB_LOG_DEBUG("{} : Set PolicyAttributes->CorrectionInMs: {}[{}]",
                         nmPath(domainId, policyId), ec.message(), ec.value());
        if (ec)
        {
            handleError(ec);
            return;
        }
        enablePolicy(nmServiceName, domainId, policyId, handleError);
        });
}

static void patchPowerPowerControlPowerLimitLimitInWatts(
    const std::shared_ptr<SensorsAsyncResp>& sensorAsyncResp,
    const DomainId& domainId, const PolicyId& policyId,
    const std::string& nmServiceName, uint16_t limitInWatts)
{
    BMCWEB_LOG_DEBUG("patchPowerPowerControlPowerLimitLimitInWatts");
    auto handleError = handleSetPropertyError(sensorAsyncResp, "LimitInWatts",
                                              limitInWatts);

    auto limit = limitInWatts;
    sdbusplus::asio::setProperty<uint16_t>(
        *crow::connections::systemBus, nmServiceName,
        nmPath(domainId, policyId), kPolicyAttributesInterface, "Limit",
        std::move(limit),
        [domainId, policyId, handleError, sensorAsyncResp,
         nmServiceName](boost::system::error_code ec) {
        BMCWEB_LOG_DEBUG("{} : Set PolicyAttributes->Limit: {}[{}]",
                         nmPath(domainId, policyId), ec.message(), ec.value());
        if (ec)
        {
            handleError(ec);
            return;
        }
        enablePolicy(nmServiceName, domainId, policyId, handleError);
        });
}

static void patchPowerPowerControlPowerLimitLimitException(
    const std::shared_ptr<SensorsAsyncResp>& sensorAsyncResp,
    const DomainId& domainId, const PolicyId& policyId,
    const std::string& nmServiceName, std::string limitExceptionStr)
{
    BMCWEB_LOG_DEBUG("patchPowerPowerControlPowerLimitLimitException");
    std::optional<int32_t> limitException =
        limitExceptionToInt(limitExceptionStr);
    if (!limitException)
    {
        messages::propertyValueIncorrect(sensorAsyncResp->asyncResp->res,
                                         "LimitException", limitExceptionStr);
        return;
    }
    auto handleError = handleSetPropertyError(sensorAsyncResp, "LimitException",
                                              *limitException);
    auto limitExc = *limitException;
    sdbusplus::asio::setProperty<int32_t>(
        *crow::connections::systemBus, nmServiceName,
        nmPath(domainId, policyId), kPolicyAttributesInterface,
        "LimitException", std::move(limitExc),
        [domainId, policyId, handleError, sensorAsyncResp,
         nmServiceName](boost::system::error_code ec) {
        BMCWEB_LOG_DEBUG("{} : Set PolicyAttributes->LimitException: {}[{}]",
                         nmPath(domainId, policyId), ec.message(), ec.value());
        if (ec)
        {
            handleError(ec);
            return;
        }
        enablePolicy(nmServiceName, domainId, policyId, handleError);
        });
}

static void patchPowerPowerControlOemOpenBmcPowerLimitStorage(
    const std::shared_ptr<SensorsAsyncResp>& sensorAsyncResp,
    const DomainId& domainId, const PolicyId& policyId,
    const std::string& nmServiceName, std::string powerLimitStorageStr)
{
    BMCWEB_LOG_DEBUG("patchPowerPowerControlOemOpenBmcPowerLimitStorage");
    std::optional<int32_t> powerLimitStorage =
        powerLimitStorageToInt(powerLimitStorageStr);
    if (!powerLimitStorage)
    {
        messages::propertyValueIncorrect(sensorAsyncResp->asyncResp->res,
                                         "PowerLimitStorage",
                                         powerLimitStorageStr);
        return;
    }
    auto handleError = handleSetPropertyError(
        sensorAsyncResp, "PowerLimitStorage", *powerLimitStorage);
    auto limitStorage = *powerLimitStorage;
    sdbusplus::asio::setProperty<int32_t>(
        *crow::connections::systemBus, nmServiceName,
        nmPath(domainId, policyId), kPolicyAttributesInterface, "PolicyStorage",
        std::move(limitStorage),
        [domainId, policyId, handleError, sensorAsyncResp,
         nmServiceName](boost::system::error_code ec) {
        BMCWEB_LOG_DEBUG("{} : Set PolicyAttributes->PolicyStorage: {}[{}]",
                         nmPath(domainId, policyId), ec.message(), ec.value());
        if (ec)
        {
            handleError(ec);
            return;
        }
        });
}

static void patchPowerPowerControlPowerLimit(
    const std::shared_ptr<SensorsAsyncResp>& sensorAsyncResp,
    const DomainId& domainId, const PolicyId& policyId,
    const DeviceIndex deviceIndex, const std::string& nmServiceName,
    nlohmann::json& json)
{
    BMCWEB_LOG_DEBUG("patchPowerPowerControlPowerLimit");
    if (json.contains("LimitInWatts") && json["LimitInWatts"].is_null())
    {
        updatePolicyToDefaults(sensorAsyncResp, domainId, policyId,
                               nmServiceName, deviceIndex);
        json.erase("LimitInWatts");
        if (json.empty())
        {
            return;
        }
    }
    if (json.contains("LimitException") && json["LimitException"].is_null())
    {
        updatePolicyToDefaults(sensorAsyncResp, domainId, policyId,
                               nmServiceName, deviceIndex);
        json.erase("LimitException");
        if (json.empty())
        {
            return;
        }
    }
    if (json.contains("CorrectionInMs") && json["CorrectionInMs"].is_null())
    {
        updatePolicyToDefaults(sensorAsyncResp, domainId, policyId,
                               nmServiceName, deviceIndex);
        json.erase("CorrectionInMs");
        if (json.empty())
        {
            return;
        }
    }

    std::optional<uint16_t> limitInWatts;
    std::optional<std::string> limitException;
    std::optional<uint32_t> correctionInMs;
    if (!json_util::readJson(json, sensorAsyncResp->asyncResp->res,
                             "LimitInWatts", limitInWatts, "LimitException",
                             limitException, "CorrectionInMs", correctionInMs))
    {
        return;
    }
    if (limitInWatts)
    {
        patchPowerPowerControlPowerLimitLimitInWatts(
            sensorAsyncResp, domainId, policyId, nmServiceName, *limitInWatts);
    }
    if (limitException)
    {
        patchPowerPowerControlPowerLimitLimitException(
            sensorAsyncResp, domainId, policyId, nmServiceName,
            *limitException);
    }
    if (correctionInMs)
    {
        patchPowerPowerControlPowerLimitCorrectionInMs(
            sensorAsyncResp, domainId, policyId, nmServiceName,
            *correctionInMs);
    }
}

static void patchPowerPowerControlOemOpenBmc(
    const std::shared_ptr<SensorsAsyncResp>& sensorAsyncResp,
    const DomainId& domainId, const PolicyId& policyId,
    const std::string& nmServiceName, nlohmann::json& json)
{
    BMCWEB_LOG_DEBUG("patchPowerPowerControlOemOpenBmc");
    if (json.contains("PowerLimitStorage") &&
        json["PowerLimitStorage"].is_null())
    {
        json.erase("PowerLimitStorage");
        if (json.empty())
        {
            return;
        }
    }

    std::optional<std::string> powerLimitStorage;
    if (!json_util::readJson(json, sensorAsyncResp->asyncResp->res,
                             "PowerLimitStorage", powerLimitStorage))
    {
        return;
    }
    if (powerLimitStorage)
    {
        patchPowerPowerControlOemOpenBmcPowerLimitStorage(
            sensorAsyncResp, domainId, policyId, nmServiceName,
            *powerLimitStorage);
    }
}

static void patchPowerPowerControlOem(
    const std::shared_ptr<SensorsAsyncResp>& sensorAsyncResp,
    const DomainId& domainId, const PolicyId& policyId,
    const std::string& nmServiceName, nlohmann::json& json)
{
    BMCWEB_LOG_DEBUG("patchPowerPowerControlOem");
    if (json.contains("OpenBmc") && json["OpenBmc"].is_null())
    {
        json.erase("OpenBmc");
        if (json.empty())
        {
            return;
        }
    }

    std::optional<nlohmann::json> openBmc;
    if (!json_util::readJson(json, sensorAsyncResp->asyncResp->res, "OpenBmc",
                             openBmc))
    {
        return;
    }
    if (openBmc)
    {
        patchPowerPowerControlOemOpenBmc(sensorAsyncResp, domainId, policyId,
                                         nmServiceName, *openBmc);
    }
}

static void
    getPowerLimit(const std::shared_ptr<SensorsAsyncResp>& sensorAsyncResp,
                  const DomainId& domainId, const PolicyId& policyId,
                  const size_t idx, const std::string& nmServiceName,
                  const std::shared_ptr<FinalCallback> finalCallback = nullptr)
{
    BMCWEB_LOG_DEBUG("getPowerLimit");
    auto setJsonPowerLimit =
        [sensorAsyncResp, idx](const std::string& key, const auto& value) {
        nlohmann::json& json = sensorAsyncResp->asyncResp->res.jsonValue;
        if constexpr (std::numeric_limits<decltype(value)>::has_quiet_NaN)
        {
            if (std::isnan(value))
            {
                json["PowerControl"][idx]["PowerLimit"][key] = nlohmann::json();
            }
            else
            {
                json["PowerControl"][idx]["PowerLimit"][key] = value;
            }
        }
        else
        {
            json["PowerControl"][idx]["PowerLimit"][key] = value;
        }
    };

    setJsonPowerLimit("LimitException",
                      std::numeric_limits<double>::quiet_NaN());
    setJsonPowerLimit("LimitInWatts", std::numeric_limits<double>::quiet_NaN());
    setJsonPowerLimit("CorrectionInMs",
                      std::numeric_limits<double>::quiet_NaN());

    sdbusplus::asio::getAllProperties(
        *crow::connections::systemBus, nmServiceName,
        nmPath(domainId, policyId), kPolicyAttributesInterface,
        [domainId, policyId, sensorAsyncResp, setJsonPowerLimit, finalCallback](
            boost::system::error_code ec,
            const std::vector<std::pair<
                std::string, std::variant<std::monostate, uint16_t, int32_t,
                                          uint32_t>>>& properties) {
        BMCWEB_LOG_DEBUG("{} : PolicyAttributes: {}[{}]",
                         nmPath(domainId, policyId), ec.message(), ec.value());
        if (ec)
        {
            return;
        }
        try
        {
            uint16_t limit = 0;
            int32_t limitException = 0;
            uint32_t correctionTimeMs = 0;
            int32_t policyState = 0;
            sdbusplus::unpackProperties(
                properties, "Limit", limit, "LimitException", limitException,
                "CorrectionInMs", correctionTimeMs, "PolicyState", policyState);

            if (isPolicyStateEnabled(policyState))
            {
                setJsonPowerLimit("LimitInWatts", limit);
                setJsonPowerLimit("CorrectionInMs", correctionTimeMs);
                if (auto limitExStr = limitExceptionToStr(limitException))
                {
                    setJsonPowerLimit("LimitException", *limitExStr);
                }
            }
        }
        catch (const sdbusplus::exception::UnpackPropertyError& error)
        {
            BMCWEB_LOG_ERROR("{}", error.what());
            messages::internalError(sensorAsyncResp->asyncResp->res);
        }
        });
}

static void getOem(const std::shared_ptr<SensorsAsyncResp>& sensorAsyncResp,
                   const DomainId& domainId, const PolicyId& policyId,
                   const size_t idx, const std::string& nmServiceName,
                   const std::shared_ptr<FinalCallback> finalCallback = nullptr)
{
    BMCWEB_LOG_DEBUG("getOem");
    auto setJsonOemPowerLimitStorage =
        [sensorAsyncResp, idx](const std::optional<std::string>& value) {
        nlohmann::json& json = sensorAsyncResp->asyncResp->res.jsonValue;

        json["PowerControl"][idx]["Oem"]["OpenBmc"]["@odata.type"] =
            "#OemPower.PowerControl";

        if (value)
        {
            json["PowerControl"][idx]["Oem"]["OpenBmc"]["PowerLimitStorage"] =
                *value;
        }
        else
        {
            json["PowerControl"][idx]["Oem"]["OpenBmc"]["PowerLimitStorage"] =
                nlohmann::json();
        }
    };

    setJsonOemPowerLimitStorage(std::nullopt);

    sdbusplus::asio::getAllProperties(
        *crow::connections::systemBus, nmServiceName,
        nmPath(domainId, policyId), kPolicyAttributesInterface,
        [domainId, policyId, sensorAsyncResp, setJsonOemPowerLimitStorage,
         finalCallback](
            boost::system::error_code ec,
            const std::vector<std::pair<
                std::string, std::variant<std::monostate, uint16_t, int32_t,
                                          uint32_t>>>& properties) {
        BMCWEB_LOG_DEBUG("{} : PolicyAttributes: {}[{}]",
                         nmPath(domainId, policyId), ec.message(), ec.value());
        if (ec)
        {
            return;
        }
        try
        {
            int32_t policyStorage = 0;
            sdbusplus::unpackProperties(properties, "PolicyStorage",
                                        policyStorage);

            setJsonOemPowerLimitStorage(powerLimitStorageToStr(policyStorage));
        }
        catch (const sdbusplus::exception::UnpackPropertyError& error)
        {
            BMCWEB_LOG_ERROR("{}", error.what());
            messages::internalError(sensorAsyncResp->asyncResp->res);
        }
        });
}

static void getAllocatedAndRequestedWatts(
    const std::shared_ptr<SensorsAsyncResp>& sensorAsyncResp,
    const DomainId& domainId, const PolicyId& policyId,
    const size_t powerControlIdx, const std::string& nmServiceName,
    const std::shared_ptr<FinalCallback> finalCallback = nullptr)
{
    BMCWEB_LOG_DEBUG("getAllocatedAndRequestedWatts");

    auto setJsonPowerRequestedWatts =
        [sensorAsyncResp, powerControlIdx](const auto& value) {
        nlohmann::json& json = sensorAsyncResp->asyncResp->res.jsonValue;
        nlohmann::json& powerControl = json["PowerControl"][powerControlIdx];

        powerControl["PowerRequestedWatts"] = value;
    };

    setJsonPowerRequestedWatts(nlohmann::json());

    auto setJsonPowerAllocatedWatts =
        [sensorAsyncResp, powerControlIdx](const auto& value) {
        nlohmann::json& json = sensorAsyncResp->asyncResp->res.jsonValue;
        nlohmann::json& powerControl = json["PowerControl"][powerControlIdx];

        powerControl["PowerAllocatedWatts"] = value;
    };
    setJsonPowerAllocatedWatts(nlohmann::json());

    sdbusplus::asio::getProperty<uint16_t>(
        *crow::connections::systemBus, nmServiceName,
        nmPath(domainId, policyId), kPolicyAttributesInterface, "Limit",
        [domainId, sensorAsyncResp, setJsonPowerRequestedWatts,
         setJsonPowerAllocatedWatts,
         finalCallback](boost::system::error_code ec, uint16_t limit) {
        BMCWEB_LOG_DEBUG("{} : Get PolicyAttributes->Limit: {}[{}]",
                         nmPath(domainId, dmtfPowerPolicyId), ec.message(),
                         ec.value());
        if (ec)
        {
            return;
        }
        setJsonPowerRequestedWatts(limit);
        setJsonPowerAllocatedWatts(limit);
        });
}

static void getCapacityConsumedWattsInputRange(
    const std::shared_ptr<SensorsAsyncResp>& sensorAsyncResp,
    const DomainId& domainId, const PolicyId& policyId,
    const size_t componentId, size_t powerControlIdx,
    const std::string& nmServiceName,
    const std::shared_ptr<FinalCallback> finalCallback = nullptr)
{
    BMCWEB_LOG_DEBUG("getCapacityConsumedWattsInputRange");
    auto setJsonPower = [sensorAsyncResp, powerControlIdx](
                            const std::string& key, const auto& value) {
        nlohmann::json& json = sensorAsyncResp->asyncResp->res.jsonValue;
        if (std::isnan(value))
        {
            json["PowerControl"][powerControlIdx][key] = nlohmann::json();
        }
        else
        {
            json["PowerControl"][powerControlIdx][key] = value;
        }
    };

    setJsonPower("PowerCapacityWatts",
                 std::numeric_limits<double>::quiet_NaN());
    setJsonPower("PowerConsumedWatts",
                 std::numeric_limits<double>::quiet_NaN());

    crow::connections::systemBus->async_method_call(
        [domainId, sensorAsyncResp, setJsonPower, componentId, finalCallback](
            boost::system::error_code ec,
            const boost::container::flat_map<
                std::string, boost::container::flat_map<std::string, double>>&
                response) {
        BMCWEB_LOG_DEBUG("{} : GetAllLimitsCapabilities: {}[{}]",
                         nmPath(domainId), ec.message(), ec.value());
        if (ec)
        {
            return;
        }
        const auto& it =
            response.find("Component_" + std::to_string(componentId));
        if (it != response.cend())
        {
            try
            {
                setJsonPower("PowerCapacityWatts", it->second.at("Max"));
            }
            catch (const std::out_of_range& error)
            {
                logException(sensorAsyncResp, error.what());
            }
        }
        },
        nmServiceName, nmPath(domainId),
        "xyz.openbmc_project.NodeManager.Capabilities",
        "GetAllLimitsCapabilities");

    crow::connections::systemBus->async_method_call(
        [domainId, policyId, sensorAsyncResp, setJsonPower, finalCallback](
            boost::system::error_code ec,
            const boost::container::flat_map<
                std::string,
                std::vector<std::pair<std::string,
                                      std::variant<std::monostate, double>>>>&
                response) {
        BMCWEB_LOG_DEBUG("{} : GetStatistics: {}[{}]",
                         nmPath(domainId, policyId), ec.message(), ec.value());
        if (ec)
        {
            return;
        }
        const auto& it = response.find("Power");
        if (it != response.cend())
        {
            try
            {
                double current = 0.;
                sdbusplus::unpackProperties(it->second, "Current", current);
                setJsonPower("PowerConsumedWatts", current);
            }
            catch (const sdbusplus::exception::UnpackPropertyError& error)
            {
                BMCWEB_LOG_ERROR("{}", error.what());
                messages::internalError(sensorAsyncResp->asyncResp->res);
            }
        }
        },
        nmServiceName, nmPath(domainId, policyId), kPolicyStatisticsInterface,
        "GetStatistics");
}

static void getCapacityConsumedWattsInputRange(
    const std::shared_ptr<SensorsAsyncResp>& sensorAsyncResp,
    const DomainId& domainId, size_t powerControlIdx,
    const std::string& nmServiceName,
    const std::shared_ptr<FinalCallback> finalCallback = nullptr)
{
    BMCWEB_LOG_DEBUG("getCapacityConsumedWattsInputRange");
    auto setJsonPower = [sensorAsyncResp, powerControlIdx](
                            const std::string& key, const auto& value) {
        nlohmann::json& json = sensorAsyncResp->asyncResp->res.jsonValue;
        if (std::isnan(value))
        {
            json["PowerControl"][powerControlIdx][key] = nlohmann::json();
        }
        else
        {
            json["PowerControl"][powerControlIdx][key] = value;
        }
    };

    setJsonPower("PowerCapacityWatts",
                 std::numeric_limits<double>::quiet_NaN());
    setJsonPower("PowerConsumedWatts",
                 std::numeric_limits<double>::quiet_NaN());

    sdbusplus::asio::getProperty<double>(
        *crow::connections::systemBus, nmServiceName, nmPath(domainId),
        "xyz.openbmc_project.NodeManager.Capabilities", "Max",
        [domainId, setJsonPower, finalCallback](boost::system::error_code ec,
                                                double max) {
        BMCWEB_LOG_DEBUG("{} : Get Capabilities->Max: {}[{}]", nmPath(domainId),
                         ec.message(), ec.value());
        if (ec)
        {
            return;
        }
        if (!std::isnan(max))
        {
            setJsonPower("PowerCapacityWatts", max);
        }
        });

    crow::connections::systemBus->async_method_call(
        [domainId, sensorAsyncResp, setJsonPower, finalCallback](
            boost::system::error_code ec,
            const boost::container::flat_map<
                std::string,
                std::vector<std::pair<std::string,
                                      std::variant<std::monostate, double>>>>&
                response) {
        BMCWEB_LOG_DEBUG("{} : GetStatistics: {}[{}]", nmPath(domainId),
                         ec.message(), ec.value());
        if (ec)
        {
            return;
        }
        const auto& it = response.find("Power");
        if (it != response.cend())
        {
            try
            {
                double current = 0.;
                sdbusplus::unpackProperties(it->second, "Current", current);
                setJsonPower("PowerConsumedWatts", current);
            }
            catch (const sdbusplus::exception::UnpackPropertyError& error)
            {
                BMCWEB_LOG_ERROR("{}", error.what());
                messages::internalError(sensorAsyncResp->asyncResp->res);
            }
        }
        },
        nmServiceName, nmPath(domainId), kPolicyStatisticsInterface,
        "GetStatistics");
}

static void getPowerMetrics(
    const std::shared_ptr<SensorsAsyncResp>& sensorAsyncResp,
    const DomainId& domainId, const PolicyId& policyId, size_t powerControlIdx,
    const std::string& nmServiceName,
    const std::shared_ptr<FinalCallback> finalCallback = nullptr)
{
    BMCWEB_LOG_DEBUG("getPowerMetrics");
    auto setJsonPowerMetrics =
        [sensorAsyncResp, powerControlIdx](
            const std::string& key,
            const std::variant<double, uint32_t, uint64_t, bool>& valueVar) {
        nlohmann::json& json = sensorAsyncResp->asyncResp->res.jsonValue;
        std::visit(
            [&json, &powerControlIdx, &key](auto& value) {
            if (std::isnan(value))
            {
                json["PowerControl"][powerControlIdx]["PowerMetrics"][key] =
                    nlohmann::json();
            }
            else
            {
                json["PowerControl"][powerControlIdx]["PowerMetrics"][key] =
                    value;
            }
            },
            valueVar);
    };

    auto setJsonPowerMetricsInterval =
        [sensorAsyncResp, powerControlIdx](
            const std::variant<double, uint32_t, uint64_t, bool>& valueVar) {
        nlohmann::json& json = sensorAsyncResp->asyncResp->res.jsonValue;
        if (auto seconds = std::get_if<uint32_t>(&valueVar))
        {
            auto minutes = std::chrono::duration_cast<std::chrono::minutes>(
                std::chrono::seconds{*seconds});
            json["PowerControl"][powerControlIdx]["PowerMetrics"]
                ["IntervalInMin"] = minutes.count();
        }
    };

    setJsonPowerMetrics("AverageConsumedWatts",
                        std::numeric_limits<uint32_t>::quiet_NaN());
    setJsonPowerMetrics("IntervalInMin",
                        std::numeric_limits<double>::quiet_NaN());
    setJsonPowerMetrics("MaxConsumedWatts",
                        std::numeric_limits<double>::quiet_NaN());
    setJsonPowerMetrics("MinConsumedWatts",
                        std::numeric_limits<double>::quiet_NaN());

    crow::connections::systemBus->async_method_call(
        [domainId, policyId, sensorAsyncResp, setJsonPowerMetrics,
         setJsonPowerMetricsInterval, finalCallback](
            const boost::system::error_code ec,
            const boost::container::flat_map<
                std::string, boost::container::flat_map<
                                 std::string, std::variant<double, uint32_t,
                                                           uint64_t, bool>>>&
                response) {
        BMCWEB_LOG_DEBUG("{} : GetStatistics: {}[{}]",
                         nmPath(domainId, policyId), ec.message(), ec.value());
        if (ec)
        {
            return;
        }
        const auto& it = response.find("Power");
        if (it != response.cend())
        {
            try
            {
                const auto& maxIt = it->second.find("Max");
                const auto& minIt = it->second.find("Min");
                const auto& averageIt = it->second.find("Average");
                const auto& statisticsReportingPeriodIt =
                    it->second.find("StatisticsReportingPeriod");

                if (maxIt != it->second.cend())
                {
                    setJsonPowerMetrics("MaxConsumedWatts", maxIt->second);
                }
                if (minIt != it->second.cend())
                {
                    setJsonPowerMetrics("MinConsumedWatts", minIt->second);
                }
                if (averageIt != it->second.cend())
                {
                    setJsonPowerMetrics("AverageConsumedWatts",
                                        averageIt->second);
                }
                if (statisticsReportingPeriodIt != it->second.cend())
                {
                    setJsonPowerMetricsInterval(
                        statisticsReportingPeriodIt->second);
                }
            }
            catch (const sdbusplus::exception::UnpackPropertyError& error)
            {
                BMCWEB_LOG_ERROR("{}", error.what());
                messages::internalError(sensorAsyncResp->asyncResp->res);
            }
        }
        },
        nmServiceName, nmPath(domainId, policyId), kPolicyStatisticsInterface,
        "GetStatistics");
}

static void
    getStatus(const std::shared_ptr<SensorsAsyncResp>& sensorAsyncResp,
              const DomainId& domainId, const PolicyId& policyId,
              const size_t powerControlIdx, const std::string& nmServiceName,
              const std::shared_ptr<FinalCallback> finalCallback = nullptr)
{
    BMCWEB_LOG_DEBUG("getStatus");
    auto setJsonStatus =
        [sensorAsyncResp, powerControlIdx](const PolicyState& policyState) {
        nlohmann::json& json = sensorAsyncResp->asyncResp->res.jsonValue;
        std::string state, health;

        switch (policyState)
        {
            case PolicyState::disabled:
                state = "Disabled";
                health = "OK";
                break;
            case PolicyState::suspended:
                state = "StandbyOffline";
                health = "Warning";
                break;
            case PolicyState::pending:
                state = "StandbyOffline";
                health = "OK";
                break;
            case PolicyState::ready:
            case PolicyState::triggered:
            case PolicyState::selected:
                state = "Enabled";
                health = "OK";
                break;
            default:
                BMCWEB_LOG_DEBUG("Cannot match policy state value");
                return;
        }

        json["PowerControl"][powerControlIdx]["Status"]["State"] = state;
        json["PowerControl"][powerControlIdx]["Status"]["Health"] = health;
    };

    sdbusplus::asio::getAllProperties(
        *crow::connections::systemBus, nmServiceName,
        nmPath(domainId, policyId), kPolicyAttributesInterface,
        [domainId, policyId, sensorAsyncResp, setJsonStatus, finalCallback](
            boost::system::error_code ec,
            const std::vector<std::pair<
                std::string, std::variant<std::monostate, uint16_t, int32_t,
                                          uint32_t>>>& properties) {
        BMCWEB_LOG_DEBUG("{} : PolicyAttributes: {}[{}]",
                         nmPath(domainId, policyId), ec.message(), ec.value());
        if (ec)
        {
            return;
        }
        try
        {
            int32_t policyState = 0;
            sdbusplus::unpackProperties(properties, "PolicyState", policyState);
            setJsonStatus(static_cast<PolicyState>(policyState));
        }
        catch (const sdbusplus::exception::UnpackPropertyError& error)
        {
            BMCWEB_LOG_ERROR("{}", error.what());
            messages::internalError(sensorAsyncResp->asyncResp->res);
        }
        });
}

static void getPowerControlComponentNode(
    const std::shared_ptr<SensorsAsyncResp>& sensorAsyncResp,
    const std::string& nmServiceName, const DomainId& domainId,
    const DeviceIndex deviceIndex, const size_t powerControlIdx,
    const std::string& name, const size_t aggregatorIdx,
    const std::function<void()>& callback = nullptr)
{
    BMCWEB_LOG_DEBUG("getPowerControlNode node: {} powerControlIdx: {}", name,
                     powerControlIdx);
    std::string nameId = name + std::to_string(deviceIndex);
    nlohmann::json& json = sensorAsyncResp->asyncResp->res.jsonValue;
    json["PowerControl"][powerControlIdx]["RelatedItem@odata.count"] = 0;
    json["PowerControl"][powerControlIdx]["MemberId"] = nameId;
    json["PowerControl"][powerControlIdx]["Name"] = nameId + " Power Control";
    json["PowerControl"][powerControlIdx]["@odata.id"] =
        "/redfish/v1/Chassis/" + sensorAsyncResp->chassisId +
        "/Power/PowerControl/" + nameId;
    json["PowerControl"][powerRootNode]["RelatedItem"].push_back(
        {{"@odata.id", json["PowerControl"][powerControlIdx]["@odata.id"]}});
    json["PowerControl"][aggregatorIdx]["RelatedItem"].push_back(
        {{"@odata.id", json["PowerControl"][powerControlIdx]["@odata.id"]}});
    json["PowerControl"][powerControlIdx]["RelatedItem"] =
        nlohmann::json::array();
    json["PowerControl"][powerControlIdx]["@odata.type"] =
        "#Power.v1_1_0.PowerControl";

    std::shared_ptr<FinalCallback> finalCallback =
        std::make_shared<FinalCallback>([callback]() {
            if (callback)
            {
                callback();
            }
        });

    std::string policyId = nmPolicyName(name, deviceIndex);
    getAllocatedAndRequestedWatts(sensorAsyncResp, domainId, policyId,
                                  powerControlIdx, nmServiceName,
                                  finalCallback);
    getCapacityConsumedWattsInputRange(sensorAsyncResp, domainId, policyId,
                                       deviceIndex, powerControlIdx,
                                       nmServiceName, finalCallback);
    getPowerLimit(sensorAsyncResp, domainId, policyId, powerControlIdx,
                  nmServiceName, finalCallback);
    getOem(sensorAsyncResp, domainId, policyId, powerControlIdx, nmServiceName,
           finalCallback);
    getPowerMetrics(sensorAsyncResp, domainId, policyId, powerControlIdx,
                    nmServiceName, finalCallback);
    getStatus(sensorAsyncResp, domainId, policyId, powerControlIdx,
              nmServiceName, finalCallback);
}

static void getPowerControlAggregateNode(
    const std::shared_ptr<SensorsAsyncResp>& sensorAsyncResp,
    const std::string& nmServiceName, const std::string& aggregatorName,
    size_t powerControlIdx, const DomainId& domainId,
    const std::function<void()>& callback = nullptr)
{
    BMCWEB_LOG_DEBUG(
        "getPowerControlAggregateNode node: {} powerControlIdx: {}",
        aggregatorName, powerControlIdx);
    nlohmann::json& json = sensorAsyncResp->asyncResp->res.jsonValue;
    json["PowerControl"][powerControlIdx]["MemberId"] = aggregatorName;
    if (aggregatorName == "0")
    {
        json["PowerControl"][powerControlIdx]["Name"] = "System Power Control";
    }
    else
    {
        json["PowerControl"][powerControlIdx]["Name"] = aggregatorName +
                                                        " Power Control";
    }
    json["PowerControl"][powerControlIdx]["@odata.id"] =
        "/redfish/v1/Chassis/" + sensorAsyncResp->chassisId +
        "/Power/PowerControl/" + aggregatorName;
    json["PowerControl"][powerControlIdx]["@odata.type"] =
        "#Power.v1_1_0.PowerControl";
    json["PowerControl"][powerRootNode]["RelatedItem"].push_back(
        {{"@odata.id", json["PowerControl"][powerControlIdx]["@odata.id"]}});

    std::shared_ptr<FinalCallback> finalCallback =
        std::make_shared<FinalCallback>([callback]() {
            if (callback)
            {
                callback();
            }
        });

    std::string policyId = nmPolicyName(aggregatorName);
    getAllocatedAndRequestedWatts(sensorAsyncResp, domainId, policyId,
                                  powerControlIdx, nmServiceName,
                                  finalCallback);
    getCapacityConsumedWattsInputRange(sensorAsyncResp, domainId,
                                       powerControlIdx, nmServiceName,
                                       finalCallback);
    getPowerLimit(sensorAsyncResp, domainId, policyId, powerControlIdx,
                  nmServiceName, finalCallback);
    getOem(sensorAsyncResp, domainId, policyId, powerControlIdx, nmServiceName,
           finalCallback);
    getPowerMetrics(sensorAsyncResp, domainId, policyId, powerControlIdx,
                    nmServiceName, finalCallback);
    getStatus(sensorAsyncResp, domainId, policyId, powerControlIdx,
              nmServiceName, finalCallback);
}

static void
    getNmDmtfGroup(const std::shared_ptr<SensorsAsyncResp>& sensorAsyncResp,
                   const std::string& nmServiceName,
                   size_t powerControlOffsetIdx,
                   const std::vector<DeviceIndex>& components,
                   const std::string& aggregatorName,
                   const std::string& nodePrefixName, const DomainId& domainId)
{
    BMCWEB_LOG_DEBUG("getNmDmtfGroup node: {} powerControlIdx: {}",
                     aggregatorName, powerControlOffsetIdx);
    nlohmann::json& json = sensorAsyncResp->asyncResp->res.jsonValue;
    json["PowerControl"][powerControlOffsetIdx + components.size()]
        ["RelatedItem@odata.count"] = components.size();
    json["PowerControl"][powerControlOffsetIdx + components.size()]
        ["RelatedItem"] = nlohmann::json::array();
    getPowerControlAggregateNode(sensorAsyncResp, nmServiceName, aggregatorName,
                                 powerControlOffsetIdx + components.size(),
                                 domainId);

    for (size_t idx = 0; idx < components.size(); idx++)
    {
        getPowerControlComponentNode(
            sensorAsyncResp, nmServiceName, domainId, components[idx],
            powerControlOffsetIdx + idx, nodePrefixName,
            powerControlOffsetIdx + components.size());
    }
}

static void
    collectNmDmtfData(const std::shared_ptr<SensorsAsyncResp>& sensorAsyncResp,
                      const std::string& nmServiceName,
                      const std::vector<DeviceIndex>& processors,
                      const std::vector<DeviceIndex>& memories,
                      const std::vector<DeviceIndex>& accelerators)
{
    BMCWEB_LOG_DEBUG("collectNmDmtfData");
    nlohmann::json& json = sensorAsyncResp->asyncResp->res.jsonValue;
    json["PowerControl"][powerRootNode]["RelatedItem@odata.count"] =
        processors.size() + memories.size() + accelerators.size() + 3;
    json["PowerControl"][powerRootNode]["MemberId"] = "0";
    json["PowerControl"][powerRootNode]["Name"] = "System Power Control";
    json["PowerControl"][powerRootNode]["@odata.id"] =
        "/redfish/v1/Chassis/" + sensorAsyncResp->chassisId +
        "/Power/PowerControl/0";
    json["PowerControl"][powerRootNode]["@odata.type"] =
        "#Power.v1_1_0.PowerControl";
    getAllocatedAndRequestedWatts(sensorAsyncResp, dcTotalPowerDomainId,
                                  dmtfPowerPolicyId, powerRootNode,
                                  nmServiceName);
    getCapacityConsumedWattsInputRange(sensorAsyncResp, dcTotalPowerDomainId,
                                       powerRootNode, nmServiceName);
    getPowerLimit(sensorAsyncResp, dcTotalPowerDomainId, dmtfPowerPolicyId,
                  powerRootNode, nmServiceName);
    getOem(sensorAsyncResp, dcTotalPowerDomainId, dmtfPowerPolicyId,
           powerRootNode, nmServiceName);
    getPowerMetrics(sensorAsyncResp, dcTotalPowerDomainId, dmtfPowerPolicyId,
                    powerRootNode, nmServiceName);
    getStatus(sensorAsyncResp, dcTotalPowerDomainId, dmtfPowerPolicyId,
              powerRootNode, nmServiceName);

    getNmDmtfGroup(sensorAsyncResp, nmServiceName, 1, accelerators,
                   "Accelerators", "Accelerator", pcieDomainId);
    getNmDmtfGroup(sensorAsyncResp, nmServiceName, 2 + accelerators.size(),
                   processors, "Processors", "Processor", cpuDomainId);
    getNmDmtfGroup(sensorAsyncResp, nmServiceName,
                   3 + accelerators.size() + processors.size(), memories,
                   "Memories", "Memory", memoryDomainId);
}

static void
    getComponents(const std::shared_ptr<SensorsAsyncResp>& sensorAsyncResp,
                  const std::string& nmServiceName,
                  std::function<void(const std::vector<DeviceIndex>&,
                                     const std::vector<DeviceIndex>&,
                                     const std::vector<DeviceIndex>&)>
                      callback,
                  std::function<void()> onError = nullptr)
{
    BMCWEB_LOG_DEBUG("getComponents");
    sdbusplus::asio::getProperty<std::vector<DeviceIndex>>(
        *crow::connections::systemBus, nmServiceName, nmPath(cpuDomainId),
        kDomainAttributesInterface, "AvailableComponents",
        [nmServiceName, sensorAsyncResp, callback, onError](
            boost::system::error_code ec, std::vector<DeviceIndex> processors) {
        BMCWEB_LOG_DEBUG("{} : Get AvailableComponents: {}",
                         nmPath(cpuDomainId), ec.message());
        if (ec)
        {
            BMCWEB_LOG_ERROR("{} : Get AvailableComponents failed: {}",
                             nmPath(cpuDomainId), ec.message());
            if (onError)
            {
                onError();
            }
            return;
        }

        sdbusplus::asio::getProperty<std::vector<DeviceIndex>>(
            *crow::connections::systemBus, nmServiceName,
            nmPath(memoryDomainId), kDomainAttributesInterface,
            "AvailableComponents",
            [nmServiceName, sensorAsyncResp, callback, onError,
             processors](boost::system::error_code ec2,
                         std::vector<DeviceIndex> memories) {
            BMCWEB_LOG_DEBUG("{} : Get AvailableComponents: {}",
                             nmPath(memoryDomainId), ec2.message());
            if (ec2)
            {
                BMCWEB_LOG_ERROR("{} : Get AvailableComponents failed: {}",
                                 nmPath(memoryDomainId), ec2.message());
                if (onError)
                {
                    onError();
                }
                return;
            }

            sdbusplus::asio::getProperty<std::vector<DeviceIndex>>(
                *crow::connections::systemBus, nmServiceName,
                nmPath(pcieDomainId), kDomainAttributesInterface,
                "AvailableComponents",
                [nmServiceName, sensorAsyncResp, callback, onError, processors,
                 memories](boost::system::error_code ec3,
                           std::vector<DeviceIndex> accelerators) {
                if (ec3)
                {
                    BMCWEB_LOG_ERROR("{} : Get AvailableComponents failed: {}",
                                     nmPath(pcieDomainId), ec3.message());
                    if (onError)
                    {
                        onError();
                    }
                    return;
                }
                callback(processors, memories, accelerators);
                });
            });
        });
}

static void buildDomainPolicyMap(
    const std::vector<DeviceIndex>& processors,
    const std::vector<DeviceIndex>& memories,
    const std::vector<DeviceIndex>& accelerators,
    std::vector<std::tuple<DomainId, PolicyId, DeviceIndex, std::string>>& list)
{
    list.push_back({dcTotalPowerDomainId, dmtfPowerPolicyId, allDevices, "0"});

    for (const auto& deviceIndex : accelerators)
    {
        list.push_back(
            {pcieDomainId,
             dmtfPowerPolicyId + std::string{"_Accelerator"} +
                 std::to_string(deviceIndex),
             deviceIndex,
             std::string{"Accelerator"} + std::to_string(deviceIndex)});
    }
    list.push_back({pcieDomainId,
                    dmtfPowerPolicyId + std::string{"_Accelerators"},
                    allDevices, "Accelerators"});

    for (const auto& deviceIndex : processors)
    {
        list.push_back(
            {cpuDomainId,
             dmtfPowerPolicyId + std::string{"_Processor"} +
                 std::to_string(deviceIndex),
             deviceIndex,
             std::string{"Processor"} + std::to_string(deviceIndex)});
    }
    list.push_back({cpuDomainId, dmtfPowerPolicyId + std::string{"_Processors"},
                    allDevices, "Processors"});

    for (const auto& deviceIndex : memories)
    {
        list.push_back({memoryDomainId,
                        dmtfPowerPolicyId + std::string{"_Memory"} +
                            std::to_string(deviceIndex),
                        deviceIndex,
                        std::string{"Memory"} + std::to_string(deviceIndex)});
    }
    list.push_back({memoryDomainId,
                    dmtfPowerPolicyId + std::string{"_Memories"}, allDevices,
                    "Memories"});
}

static void getNmDmtfComponentByMemberId(
    const std::shared_ptr<SensorsAsyncResp>& sensorAsyncResp,
    const std::string& name)
{
    BMCWEB_LOG_DEBUG("getNmDmtfComponentMemberId: {}", name);

    crow::connections::systemBus->async_method_call(
        [sensorAsyncResp,
         name](const boost::system::error_code ec,
               const dbus::utility::MapperGetObject& getObjectType) {
        if (ec)
        {
            BMCWEB_LOG_ERROR("ObjectMapper::GetObject call failed: {}", ec);
        }
        std::string nmServiceName = nm::selectNmService(getObjectType);
        BMCWEB_LOG_DEBUG("Using node manager service: {}", nmServiceName);

        getComponents(
            sensorAsyncResp, nmServiceName,
            [sensorAsyncResp, nmServiceName,
             name](const std::vector<nm::DeviceIndex>& processors,
                   const std::vector<nm::DeviceIndex>& memories,
                   const std::vector<nm::DeviceIndex>& accelerators) {
            std::vector<std::tuple<nm::DomainId, nm::PolicyId, nm::DeviceIndex,
                                   std::string>>
                list;
            buildDomainPolicyMap(processors, memories, accelerators, list);

            auto it = std::find_if(
                list.begin(), list.end(),
                [name](
                    const std::tuple<nm::DomainId, nm::PolicyId,
                                     nm::DeviceIndex, std::string>& element) {
                const auto& [domain, policy, index, memberId] = element;
                return (memberId == name);
                });

            if (it == list.end())
            {
                messages::resourceNotFound(sensorAsyncResp->asyncResp->res,
                                           "PowerControl", name);
                return;
            }

            const auto& [domain, policy, index, memberId] = *it;

            if (index == allDevices)
            {
                getPowerControlAggregateNode(sensorAsyncResp, nmServiceName,
                                             name, tempNode, domain,
                                             [sensorAsyncResp]() {
                    nlohmann::json& json =
                        sensorAsyncResp->asyncResp->res.jsonValue;
                    json = json["PowerControl"][tempNode];
                });
            }
            else
            {
                auto nameAlpha = name;
                nameAlpha.erase(
                    std::remove_if(nameAlpha.begin(), nameAlpha.end(),
                                   [](char c) { return !std::isalpha(c); }),
                    nameAlpha.end());
                getPowerControlComponentNode(sensorAsyncResp, nmServiceName,
                                             domain, index, tempNode, nameAlpha,
                                             powerRootNode,
                                             [sensorAsyncResp]() {
                    BMCWEB_LOG_DEBUG(
                        "Remove nodes 0 and 1, copy content of node 1 to root");
                    nlohmann::json& json =
                        sensorAsyncResp->asyncResp->res.jsonValue;
                    json = json["PowerControl"][tempNode];
                });
            }
            },
            [sensorAsyncResp]() {
            messages::serviceInUnknownState(sensorAsyncResp->asyncResp->res);
        });
        },
        "xyz.openbmc_project.ObjectMapper",
        "/xyz/openbmc_project/object_mapper",
        "xyz.openbmc_project.ObjectMapper", "GetObject",
        "/xyz/openbmc_project/NodeManager", std::array<const char*, 0>());
}

static void patchNmDmtfComponentByMemberId(
    const crow::Request& req,
    const std::shared_ptr<SensorsAsyncResp>& sensorAsyncResp,
    const std::string& name)
{
    BMCWEB_LOG_DEBUG("patchNmDmtfComponentMemberId: {}", name);

    sensorAsyncResp->asyncResp->res.result(
        boost::beast::http::status::no_content);
    crow::connections::systemBus->async_method_call(
        [req, sensorAsyncResp,
         name](const boost::system::error_code ec,
               const dbus::utility::MapperGetObject& getObjectType) {
        if (ec)
        {
            BMCWEB_LOG_ERROR("ObjectMapper::GetObject call failed: {}", ec);
        }
        std::string nmServiceName = nm::selectNmService(getObjectType);
        BMCWEB_LOG_DEBUG("Using node manager service: {}", nmServiceName);

        getComponents(sensorAsyncResp, nmServiceName,
                      [req, sensorAsyncResp, nmServiceName,
                       name](const std::vector<nm::DeviceIndex>& processors,
                             const std::vector<nm::DeviceIndex>& memories,
                             const std::vector<nm::DeviceIndex>& accelerators) {
            std::vector<std::tuple<nm::DomainId, nm::PolicyId, nm::DeviceIndex,
                                   std::string>>
                list;
            buildDomainPolicyMap(processors, memories, accelerators, list);

            auto it = std::find_if(
                list.begin(), list.end(),
                [name](
                    const std::tuple<nm::DomainId, nm::PolicyId,
                                     nm::DeviceIndex, std::string>& element) {
                const auto& [domain, policy, index, memberId] = element;
                return (memberId == name);
                });

            std::optional<nlohmann::json> powerLimit;
            std::optional<nlohmann::json> oem;
            if (!json_util::readJsonAction(req, sensorAsyncResp->asyncResp->res,
                                           "Oem", oem, "PowerLimit",
                                           powerLimit))
            {
                return;
            }

            if (it == list.end())
            {
                messages::resourceNotFound(sensorAsyncResp->asyncResp->res,
                                           "PowerControl", name);
                return;
            }

            const auto& [domain, policy, index, memberId] = *it;

            if (powerLimit)
            {
                nm::patchPowerPowerControlPowerLimit(
                    sensorAsyncResp, domain, policy, index, nmServiceName,
                    *powerLimit);
            }

            if (oem)
            {
                nm::patchPowerPowerControlOem(sensorAsyncResp, domain, policy,
                                              nmServiceName, *oem);
            }
        });
        },
        "xyz.openbmc_project.ObjectMapper",
        "/xyz/openbmc_project/object_mapper",
        "xyz.openbmc_project.ObjectMapper", "GetObject",
        "/xyz/openbmc_project/NodeManager", std::array<const char*, 0>());
}

} // namespace nm
} // namespace redfish
