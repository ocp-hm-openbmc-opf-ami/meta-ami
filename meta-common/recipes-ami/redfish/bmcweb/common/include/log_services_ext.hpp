#pragma once
#include "syslog.h"

#include "redfish-core/lib/log_service_header.hpp"
#include "redfish-core/lib/redfish_util.hpp"
#include "redfish-core/lib/storage.hpp"
#include "registries/privilege_registry.hpp"
#include "system_utils.hpp"

namespace redfish
{

inline void fillRaidLogEntryFromPropertyMap(
    const std::shared_ptr<bmcweb::AsyncResp>& asyncResp,
    const std::string& systemName, const dbus::utility::DBusPropertiesMap& resp,
    nlohmann::json& objectToFillOut)
{
    std::optional<DbusEventLogEntry> optEntry =
        fillDbusEventLogEntryFromPropertyMap(resp);
    if (!optEntry.has_value())
    {
        messages::internalError(asyncResp->res);
        return;
    }
    DbusEventLogEntry entry = optEntry.value();

    objectToFillOut["@odata.type"] = json_util::odataType("LogEntry");
    objectToFillOut["@odata.id"] = boost::urls::format(
        "/redfish/v1/Systems/{}/LogServices/Raid/Entries/{}", systemName,
        std::to_string(entry.Id));
    objectToFillOut["Name"] = "System Raid Log Entry";
    objectToFillOut["Id"] = std::to_string(entry.Id);
    std::string msgID, msgForm;
    LogParseError status = fillMessageEntry(entry.Message, msgID, msgForm);
    if (status != LogParseError::success)
    {
        objectToFillOut["Message"] = entry.Message;
    }
    else
    {
        objectToFillOut["MessageID"] = std::move(msgID);
        objectToFillOut["Message"] = std::move(msgForm);
    }
    objectToFillOut["Resolved"] = entry.Resolved;
    std::optional<bool> notifyAction =
        getProviderNotifyAction(entry.ServiceProviderNotify);
    if (notifyAction)
    {
        objectToFillOut["ServiceProviderNotified"] = *notifyAction;
    }
    if ((entry.Resolution != nullptr) && !entry.Resolution->empty())
    {
        objectToFillOut["Resolution"] = *entry.Resolution;
    }
    objectToFillOut["EntryType"] = "Oem";
    objectToFillOut["OemRecordFormat"] = "Raid";
    objectToFillOut["Severity"] =
        translateSeverityDbusToRedfish(entry.Severity);
    objectToFillOut["Created"] = std::move(
        timeFormat(redfish::time_utils::getDateTimeUintMs(entry.Timestamp)));
    objectToFillOut["Modified"] = std::move(timeFormat(
        redfish::time_utils::getDateTimeUintMs(entry.UpdateTimestamp)));
    if (entry.Path != nullptr)
    {
        objectToFillOut["AdditionalDataURI"] = boost::urls::format(
            "/redfish/v1/Systems/{}/LogServices/Raid/Entries/{}/attachment",
            systemName, std::to_string(entry.Id));
    }
}

inline void afterRaidLogEntriesGetManagedObjects(
    const std::shared_ptr<bmcweb::AsyncResp>& asyncResp,
    const std::string& systemName, const boost::system::error_code& ec,
    const dbus::utility::ManagedObjectType& resp)
{
    if (ec)
    {
        // TODO Handle for specific error code
        BMCWEB_LOG_ERROR("getRaidLogEntriesIfaceData resp_handler got error {}",
                         ec);
        messages::internalError(asyncResp->res);
        return;
    }
    nlohmann::json::array_t entriesArray;
    for (const auto& objectPath : resp)
    {
        dbus::utility::DBusPropertiesMap propsFlattened;
        auto isEntry =
            std::ranges::find_if(objectPath.second, [](const auto& object) {
                return object.first == "xyz.openbmc_project.Logging.Entry";
            });
        if (isEntry == objectPath.second.end())
        {
            continue;
        }
        for (const auto& interfaceMap : objectPath.second)
        {
            for (const auto& propertyMap : interfaceMap.second)
            {
                propsFlattened.emplace_back(propertyMap.first,
                                            propertyMap.second);
            }
        }
        fillRaidLogEntryFromPropertyMap(asyncResp, systemName, propsFlattened,
                                        entriesArray.emplace_back());
    }

    std::ranges::sort(entriesArray, [](const nlohmann::json& left,
                                       const nlohmann::json& right) {
        return std::stoi(left["Id"].get<std::string>()) <=
               std::stoi(right["Id"].get<std::string>());
    });
    asyncResp->res.jsonValue["Members@odata.count"] = entriesArray.size();
    asyncResp->res.jsonValue["Members"] = std::move(entriesArray);
}

inline void downloadRaidEntry(
    const std::shared_ptr<bmcweb::AsyncResp>& asyncResp,
    const std::string& systemName, const std::string& entryID,
    const std::string& dumpType)
{
    if constexpr (BMCWEB_EXPERIMENTAL_REDFISH_MULTI_COMPUTER_SYSTEM)
    {
        // Option currently returns no systems.  TBD
        messages::resourceNotFound(asyncResp->res, "ComputerSystem",
                                   systemName);
        return;
    }
    if (!system_utils::validateSystemName(asyncResp, systemName))
    {
        return;
    }

    std::string entryPath =
        sdbusplus::message::object_path("/xyz/openbmc_project/logging/raid") /
        entryID;

    dbus::utility::getProperty<std::map<std::string, std::string>>(
        "xyz.openbmc_project.Logging", entryPath,
        "xyz.openbmc_project.Logging.Entry", "AdditionalData",
        [asyncResp, dumpType,
         entryID](const boost::system::error_code& ec,
                  const std::map<std::string, std::string>& additionalData) {
            if (ec.value() == EBADR)
            {
                messages::resourceNotFound(asyncResp->res, "LogEntry", entryID);
                return;
            }
            if (ec)
            {
                BMCWEB_LOG_DEBUG(
                    "Got DBUS response error while getting AdditionalData in {}",
                    dumpType);
                return;
            }
            nlohmann::json jsonData = nlohmann::json::object();
            for (const auto& [key, value] : additionalData)
            {
                BMCWEB_LOG_DEBUG("AdditionalData: {}={}", key, value);
                jsonData[key] = value;
            }
            asyncResp->res.addHeader(boost::beast::http::field::content_type,
                                     "application/octet-stream");
            asyncResp->res.addHeader(
                boost::beast::http::field::content_disposition, "attachment");
            asyncResp->res.jsonValue = jsonData;
        });
}

inline void handleDBusRaidEntryDownloadGet(
    crow::App& app, const std::string& dumpType, const crow::Request& req,
    const std::shared_ptr<bmcweb::AsyncResp>& asyncResp,
    const std::string& systemName, const std::string& entryID)
{
    if (!redfish::setUpRedfishRoute(app, req, asyncResp))
    {
        return;
    }
    if (!system_utils::validateSystemName(asyncResp, systemName))
    {
        return;
    }
    std::string_view Accept = req.getHeaderValue("Accept");
    if (Accept.find("text/html, */*") == std::string::npos &&
        Accept.find("text/html, */*;q=0.8") == std::string::npos &&
        Accept.find("*/*") == std::string::npos &&
        Accept.find("application/json") == std::string::npos)
    {
        asyncResp->res.result(boost::beast::http::status::bad_request);
        return;
    }
    downloadRaidEntry(asyncResp, systemName, entryID, dumpType);
}

inline void dBusRaidEntryDelete(
    const std::shared_ptr<bmcweb::AsyncResp>& asyncResp, std::string logType,
    std::string entryID)
{
    dbus::utility::escapePathForDbus(entryID);

    // Process response from Logging service.
    auto respHandler = [asyncResp,
                        entryID](const boost::system::error_code& ec) {
        if (ec)
        {
            if (ec.value() == EIO)
            {
                messages::resourceNotFound(asyncResp->res, "LogEntry", entryID);
                return;
            }
            // TODO Handle for specific error code
            BMCWEB_LOG_ERROR(
                "Log Entry (DBus) doDelete respHandler got error {}", ec);
            asyncResp->res.result(
                boost::beast::http::status::internal_server_error);
            return;
        }

        messages::success(asyncResp->res);
    };

    // Make call to Logging service to request Delete Log
    crow::connections::systemBus->async_method_call(
        respHandler, "xyz.openbmc_project.Logging",
        "/xyz/openbmc_project/logging/raid",
        "xyz.openbmc_project.Collection.DeleteLogType", "DeleteLogType",
        logType, static_cast<uint32_t>(std::stoi(entryID)));
}

inline void dBusRaidEntryPatch(
    const crow::Request& req,
    const std::shared_ptr<bmcweb::AsyncResp>& asyncResp,
    const std::string& entryId)
{
    std::optional<bool> resolved;
    if (!json_util::readJsonPatch( //
            req, asyncResp->res,   //
            "Resolved", resolved   //
            ))
    {
        return;
    }
    setDbusProperty(asyncResp, "Resolved", "xyz.openbmc_project.Logging",
                    "/xyz/openbmc_project/logging/raid/" + entryId,
                    "xyz.openbmc_project.Logging.Entry", "Resolved",
                    resolved.value_or(false));
}

inline void dBusRaidEntryGet(
    const std::shared_ptr<bmcweb::AsyncResp>& asyncResp,
    const std::string& systemName, std::string entryID)
{
    dbus::utility::escapePathForDbus(entryID);

    // DBus implementation of Raid/Entries
    // Make call to Logging Service to find all log entry objects
    dbus::utility::getAllProperties(
        "xyz.openbmc_project.Logging",
        "/xyz/openbmc_project/logging/raid/" + entryID, "",
        [asyncResp, systemName,
         entryID](const boost::system::error_code& ec,
                  const dbus::utility::DBusPropertiesMap& resp) {
            if (ec.value() == EBADR)
            {
                messages::resourceNotFound(asyncResp->res, "LogEntry", entryID);
                return;
            }
            if (ec)
            {
                BMCWEB_LOG_ERROR(
                    "Raid LogEntry (DBus) resp_handler got error {}", ec);
                messages::internalError(asyncResp->res);
                return;
            }
            fillRaidLogEntryFromPropertyMap(asyncResp, systemName, resp,
                                            asyncResp->res.jsonValue);
        });
}

inline void dBusRaidEntryCollection(
    const std::shared_ptr<bmcweb::AsyncResp>& asyncResp,
    const std::string& systemName)
{
    // Collections don't include the static data added by SubRoute
    // because it has a duplicate entry for members
    asyncResp->res.jsonValue["@odata.type"] =
        json_util::odataType("LogEntryCollection");
    asyncResp->res.jsonValue["@odata.id"] = std::format(
        "/redfish/v1/Systems/{}/LogServices/Raid/Entries", systemName);
    asyncResp->res.jsonValue["Name"] = "System Raid Log Entries";
    asyncResp->res.jsonValue["Description"] =
        "Collection of System Raid Log Entries";

    // DBus implementation of EventLog/Entries
    // Make call to Logging Service to find all log entry objects
    sdbusplus::message::object_path path("/xyz/openbmc_project/logging/raid");
    dbus::utility::getManagedObjects(
        "xyz.openbmc_project.Logging", path,
        [asyncResp, systemName](const boost::system::error_code& ec,
                                const dbus::utility::ManagedObjectType& resp) {
            afterRaidLogEntriesGetManagedObjects(asyncResp, systemName, ec,
                                                 resp);
        });
}

inline void requestRoutesRaidLog(App& app)
{
    BMCWEB_ROUTE(app, "/redfish/v1/Systems/<str>/LogServices/Raid/")
        .privileges(redfish::privileges::getLogService)
        .methods(
            boost::beast::http::verb::
                get)([&app](const crow::Request& req,
                            const std::shared_ptr<bmcweb::AsyncResp>& asyncResp,
                            const std::string& systemName) {
            if (!redfish::setUpRedfishRoute(app, req, asyncResp))
            {
                return;
            }
            if (!system_utils::validateSystemName(asyncResp, systemName))
            {
                return;
            }
            asyncResp->res.jsonValue["@odata.id"] = std::format(
                "/redfish/v1/Systems/{}/LogServices/Raid", systemName);
            asyncResp->res.jsonValue["@odata.type"] =
                json_util::odataType("LogService");
            asyncResp->res.jsonValue["Name"] = "Raid Log Service";
            asyncResp->res.jsonValue["Description"] = "System Raid Log Service";
            asyncResp->res.jsonValue["Id"] = "Raid";
            asyncResp->res.jsonValue["OverWritePolicy"] =
                log_service::OverWritePolicy::WrapsWhenFull;
            asyncResp->res.jsonValue["MaxNumberOfRecords"] = 150;

            std::pair<std::string, std::string> redfishDateTimeOffset =
                redfish::time_utils::getDateTimeOffsetNow();

            asyncResp->res.jsonValue["DateTime"] = redfishDateTimeOffset.first;
            asyncResp->res.jsonValue["DateTimeLocalOffset"] =
                redfishDateTimeOffset.second;

            asyncResp->res.jsonValue["Entries"]["@odata.id"] = std::format(
                "/redfish/v1/Systems/{}/LogServices/Raid/Entries", systemName);
            asyncResp->res
                .jsonValue["Actions"]["#LogService.ClearLog"]["target"]

                = std::format(
                    "/redfish/v1/Systems/{}/LogServices/Raid/Actions/LogService.ClearLog",
                    systemName);
        });

    BMCWEB_ROUTE(app, "/redfish/v1/Systems/<str>/LogServices/Raid/Entries/")
        .privileges(redfish::privileges::getLogEntryCollection)
        .methods(boost::beast::http::verb::get)(
            [&app](const crow::Request& req,
                   const std::shared_ptr<bmcweb::AsyncResp>& asyncResp,
                   const std::string& systemName) {
                if (!redfish::setUpRedfishRoute(app, req, asyncResp))
                {
                    return;
                }
                if (!system_utils::validateSystemName(asyncResp, systemName))
                {
                    return;
                }
                dBusRaidEntryCollection(asyncResp, systemName);
            });

    BMCWEB_ROUTE(app,
                 "/redfish/v1/Systems/<str>/LogServices/Raid/Entries/<str>/")
        .privileges(redfish::privileges::getLogEntry)
        .methods(boost::beast::http::verb::get)(
            [&app](const crow::Request& req,
                   const std::shared_ptr<bmcweb::AsyncResp>& asyncResp,
                   const std::string& systemName, const std::string& entryId) {
                if (!redfish::setUpRedfishRoute(app, req, asyncResp))
                {
                    return;
                }
                if (!system_utils::validateSystemName(asyncResp, systemName))
                {
                    return;
                }

                dBusRaidEntryGet(asyncResp, systemName, entryId);
            });

    BMCWEB_ROUTE(app,
                 "/redfish/v1/Systems/<str>/LogServices/Raid/Entries/<str>/")
        .privileges(redfish::privileges::patchLogEntry)
        .methods(boost::beast::http::verb::patch)(
            [&app](const crow::Request& req,
                   const std::shared_ptr<bmcweb::AsyncResp>& asyncResp,
                   const std::string& systemName, const std::string& entryId) {
                if (!redfish::setUpRedfishRoute(app, req, asyncResp))
                {
                    return;
                }
                if (!system_utils::validateSystemName(asyncResp, systemName))
                {
                    return;
                }
                dBusRaidEntryPatch(req, asyncResp, entryId);
            });

    BMCWEB_ROUTE(app,
                 "/redfish/v1/Systems/<str>/LogServices/Raid/Entries/<str>/")
        .privileges(redfish::privileges::deleteLogEntry)
        .methods(boost::beast::http::verb::delete_)(
            [&app](const crow::Request& req,
                   const std::shared_ptr<bmcweb::AsyncResp>& asyncResp,
                   const std::string& systemName, const std::string& param) {
                if (!redfish::setUpRedfishRoute(app, req, asyncResp))
                {
                    return;
                }
                if (!system_utils::validateSystemName(asyncResp, systemName))
                {
                    return;
                }
                dBusRaidEntryDelete(asyncResp, "raid", param);
            });

    BMCWEB_ROUTE(
        app,
        "/redfish/v1/Systems/<str>/LogServices/Raid/Entries/<str>/attachment/")
        .privileges(redfish::privileges::getLogEntry)
        .methods(boost::beast::http::verb::get)(std::bind_front(
            handleDBusRaidEntryDownloadGet, std::ref(app), "RAID"));

    /**
     * Function handles POST method request.
     * The Clear Log actions does not require any parameter.The action deletes
     * all raid entries found in the Entries collection for this Log Service.
     */
    BMCWEB_ROUTE(
        app,
        "/redfish/v1/Systems/<str>/LogServices/Raid/Actions/LogService.ClearLog/")
        .privileges(redfish::privileges::postLogService)
        .methods(boost::beast::http::verb::post)(
            [&app](const crow::Request& req,
                   const std::shared_ptr<bmcweb::AsyncResp>& asyncResp,
                   const std::string& systemName) {
                if (!redfish::setUpRedfishRoute(app, req, asyncResp))
                {
                    return;
                }
                if (!system_utils::validateSystemName(asyncResp, systemName))
                {
                    return;
                }
                dBusRaidEntryDelete(asyncResp, "raid", "0");
            });
}
} // namespace redfish
