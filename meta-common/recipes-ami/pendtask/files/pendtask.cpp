#include "pendtask.hpp"

#include <nlohmann/json.hpp>
#include <phosphor-logging/log.hpp>
#include <sdbusplus/bus.hpp>
#include <snmp.hpp>
#include <snmp_notification.hpp>

#include <chrono>
#include <filesystem>
#include <fstream>
#include <iostream>
#include <mutex>
#include <thread>

/* Global configuration */
uint8_t alertsLimit_g = 0;
uint32_t timeInterval_g = 0;
uint8_t retryCount_g = 0;
std::mutex alertMapMutex;

/**
 * @struct AlertData
 * @brief Structure to hold alert information with retry scheduling
 */
struct AlertData
{
    std::string alertType;
    std::string identifier;
    std::string payload;
    uint8_t retryCount;
    uint64_t nextRetryTime; /* timestamp when to retry next */

    bool isEmpty() const
    {
        return alertType.empty() && identifier.empty() && payload.empty() &&
               retryCount == 0;
    }
};

/* Global alert queue */
std::map<uint8_t, AlertData> alertMap;

/**
 * @brief Send SMTP alert via D-Bus
 *
 * @param identifier Alert identifier
 * @param payload Alert payload
 * @return true if alert sent successfully, false otherwise
 */
bool sendSMTPAlert(std::string identifier, std::string payload)
{
    uint16_t mailstatus = 0;
    try
    {
        auto bus = sdbusplus::bus::new_default();
        auto sendAlert = bus.new_method_call(mailService, mailObjPath,
                                             mailIface, sendMailMethod);
        sendAlert.append(identifier.c_str(), payload.c_str());
        auto replyStatus = bus.call(sendAlert);
        if (replyStatus.is_method_error())
        {
            phosphor::logging::log<phosphor::logging::level::ERR>(
                "Failed to call send alert method");
            return false;
        }
        replyStatus.read(mailstatus);
        if (mailstatus != 0)
        {
            phosphor::logging::log<phosphor::logging::level::ERR>(
                "SMTP alert failed",
                phosphor::logging::entry("MAILSTATUS=%u", mailstatus));
            return false;
        }
        else
        {
            phosphor::logging::log<phosphor::logging::level::INFO>(
                "SMTP alert sent successfully");
            return true;
        }
        return (mailstatus == 0);
    }
    catch (const sdbusplus::exception_t& e)
    {
        phosphor::logging::log<phosphor::logging::level::ERR>(
            "D-Bus exception in sendSMTPAlert",
            phosphor::logging::entry("EXCEPTION=%s", e.what()));
        return false;
    }
    catch (const std::exception& e)
    {
        phosphor::logging::log<phosphor::logging::level::ERR>(
            "Exception in sendSMTPAlert",
            phosphor::logging::entry("EXCEPTION=%s", e.what()));
        return false;
    }
}

/**
 * @brief Send SNMP trap
 *
 * @param identifier Alert identifier (record ID)
 * @param payload Alert payload in JSON format
 * @return true if trap sent successfully, false otherwise
 */
bool sendSNMPAlert(std::string identifier, std::string payload)
{
    try
    {
        uint32_t recordId = static_cast<uint32_t>(std::stoul(identifier));
        auto payloadJson = nlohmann::json::parse(payload);

        /* Build a combined message from payload fields */
        std::string timeStamp = payloadJson.value("timeStamp", "");
        std::string severity = payloadJson.value("severity", "");
        std::string eventDataMsg = payloadJson.value("eventDataMsg", "");
        std::string sensorName = payloadJson.value("sensorName", "");
        std::string direction = payloadJson.value("direction", "");
        std::string hostName = payloadJson.value("hostName", "");

        /* Map severity string to integer (INFO=0, WARNING=1, CRITICAL=2) */
        int32_t sevInt = 0;
        if (severity == "Critical")
            sevInt = 2;
        else if (severity == "Warning")
            sevInt = 1;

        /* Get timestamp as epoch */
        auto now = std::chrono::system_clock::now();
        uint64_t ts = static_cast<uint64_t>(
            std::chrono::duration_cast<std::chrono::milliseconds>(
                now.time_since_epoch())
                .count());

        /* Compose message string with all alert details */
        std::string msg = sensorName + " " + direction + " " + eventDataMsg +
                          " [" + hostName + "] " + timeStamp;

        /* Use the stock 4-param constructor from sysroot */
        phosphor::network::snmp::OBMCErrorNotification notification(
            recordId, ts, sevInt, msg);

        notification.sendTrap();

        phosphor::logging::log<phosphor::logging::level::INFO>(
            "SNMP trap sent successfully");
        return true;
    }
    catch (const std::invalid_argument& e)
    {
        phosphor::logging::log<phosphor::logging::level::ERR>(
            "Invalid identifier for SNMP alert",
            phosphor::logging::entry("IDENTIFIER=%s", identifier.c_str()),
            phosphor::logging::entry("EXCEPTION=%s", e.what()));
        return false;
    }
    catch (const std::out_of_range& e)
    {
        phosphor::logging::log<phosphor::logging::level::ERR>(
            "Identifier out of range for SNMP alert",
            phosphor::logging::entry("IDENTIFIER=%s", identifier.c_str()),
            phosphor::logging::entry("EXCEPTION=%s", e.what()));
        return false;
    }
    catch (const nlohmann::json::exception& e)
    {
        phosphor::logging::log<phosphor::logging::level::ERR>(
            "JSON parse error in sendSNMPAlert",
            phosphor::logging::entry("EXCEPTION=%s", e.what()));
        return false;
    }
    catch (const std::exception& e)
    {
        phosphor::logging::log<phosphor::logging::level::ERR>(
            "Exception in sendSNMPAlert",
            phosphor::logging::entry("EXCEPTION=%s", e.what()));
        return false;
    }
    catch (...)
    {
        phosphor::logging::log<phosphor::logging::level::ERR>(
            "Unknown exception in sendSNMPAlert");
        return false;
    }
}

/**
 * @brief Remove an entry from the JSON file
 *
 * @param id Entry ID to remove
 * @return true if successful, false otherwise
 */
bool removeEntryFromJson(uint8_t id)
{
    try
    {
        nlohmann::json root;
        std::ifstream in(tasksConfFile);
        if (!in.good())
        {
            phosphor::logging::log<phosphor::logging::level::ERR>(
                "Failed to open JSON file for removing entry");
            return false;
        }
        in >> root;
        in.close();

        if (!root.is_array())
        {
            phosphor::logging::log<phosphor::logging::level::ERR>(
                "Invalid JSON format - expected array");
            return false;
        }

        /* Find the entry with matching id and clear it */
        bool found = false;
        for (auto& entry : root)
        {
            if (entry["id"] == id)
            {
                entry["alertType"] = "";
                entry["identifier"] = "";
                entry["payload"] = "";
                entry["retryCount"] = 0;
                entry["nextRetryTime"] = 0;
                found = true;
                break;
            }
        }

        if (!found)
        {
            phosphor::logging::log<phosphor::logging::level::WARNING>(
                "Entry not found in JSON",
                phosphor::logging::entry("ID=%d", id));
            return false;
        }

        std::string tempFile = std::string(tasksConfFile) + ".tmp";
        std::ofstream out(tempFile);
        if (!out.good())
        {
            phosphor::logging::log<phosphor::logging::level::ERR>(
                "Failed to open temp file for removing entry");
            return false;
        }

        out << root.dump(4);
        out.close();

        if (!out.good())
        {
            phosphor::logging::log<phosphor::logging::level::ERR>(
                "Failed to write temp file for removing entry");
            std::filesystem::remove(tempFile);
            return false;
        }

        std::filesystem::rename(tempFile, tasksConfFile);

        phosphor::logging::log<phosphor::logging::level::INFO>(
            "Successfully removed entry from JSON",
            phosphor::logging::entry("ID=%d", id));

        return true;
    }
    catch (const std::filesystem::filesystem_error& e)
    {
        phosphor::logging::log<phosphor::logging::level::ERR>(
            "Filesystem error in removeEntryFromJson",
            phosphor::logging::entry("EXCEPTION=%s", e.what()));
        return false;
    }
    catch (const nlohmann::json::exception& e)
    {
        phosphor::logging::log<phosphor::logging::level::ERR>(
            "JSON error in removeEntryFromJson",
            phosphor::logging::entry("EXCEPTION=%s", e.what()));
        return false;
    }
    catch (const std::exception& e)
    {
        phosphor::logging::log<phosphor::logging::level::ERR>(
            "Exception in removeEntryFromJson",
            phosphor::logging::entry("EXCEPTION=%s", e.what()));
        return false;
    }
}

/**
 * @brief Update an entry in the JSON file
 *
 * @param id Entry ID to update
 * @param alert Alert data to write
 * @return true if successful, false otherwise
 */
bool updateEntryInJson(uint8_t id, const AlertData& alert)
{
    try
    {
        nlohmann::json root;
        std::ifstream in(tasksConfFile);
        if (!in.good())
        {
            phosphor::logging::log<phosphor::logging::level::ERR>(
                "Failed to open JSON file for updating entry");
            return false;
        }
        in >> root;
        in.close();

        if (!root.is_array())
        {
            phosphor::logging::log<phosphor::logging::level::ERR>(
                "Invalid JSON format - expected array");
            return false;
        }

        /* Find the entry with matching id and update it */
        bool found = false;
        for (auto& entry : root)
        {
            if (entry["id"] == id)
            {
                entry["alertType"] = alert.alertType;
                entry["identifier"] = alert.identifier;
                entry["payload"] = alert.payload;
                entry["retryCount"] = alert.retryCount;
                entry["nextRetryTime"] = alert.nextRetryTime;
                found = true;
                break;
            }
        }

        if (!found)
        {
            phosphor::logging::log<phosphor::logging::level::WARNING>(
                "Entry not found in JSON for update",
                phosphor::logging::entry("ID=%d", id));
            return false;
        }

        std::string tempFile = std::string(tasksConfFile) + ".tmp";
        std::ofstream out(tempFile);
        if (!out.good())
        {
            phosphor::logging::log<phosphor::logging::level::ERR>(
                "Failed to open temp file for updating entry");
            return false;
        }

        out << root.dump(4);
        out.close();

        if (!out.good())
        {
            phosphor::logging::log<phosphor::logging::level::ERR>(
                "Failed to write temp file for updating entry");
            std::filesystem::remove(tempFile);
            return false;
        }

        std::filesystem::rename(tempFile, tasksConfFile);

        phosphor::logging::log<phosphor::logging::level::DEBUG>(
            "Successfully updated entry in JSON",
            phosphor::logging::entry("ID=%d", id),
            phosphor::logging::entry("RETRY_COUNT=%d", alert.retryCount));

        return true;
    }
    catch (const std::filesystem::filesystem_error& e)
    {
        phosphor::logging::log<phosphor::logging::level::ERR>(
            "Filesystem error in updateEntryInJson",
            phosphor::logging::entry("EXCEPTION=%s", e.what()));
        return false;
    }
    catch (const nlohmann::json::exception& e)
    {
        phosphor::logging::log<phosphor::logging::level::ERR>(
            "JSON error in updateEntryInJson",
            phosphor::logging::entry("EXCEPTION=%s", e.what()));
        return false;
    }
    catch (const std::exception& e)
    {
        phosphor::logging::log<phosphor::logging::level::ERR>(
            "Exception in updateEntryInJson",
            phosphor::logging::entry("EXCEPTION=%s", e.what()));
        return false;
    }
}

/**
 * @brief Write new task data to JSON file
 *
 * @param alertType Type of alert
 * @param identifier Alert identifier
 * @param payload Alert payload
 * @param retryCount Retry count
 * @param alertsLimit Maximum number of alerts
 * @param nextRetryTime Unix timestamp for next retry
 * @return true if successful, false otherwise
 */
bool writeTaskData(const std::string& alertType, const std::string& identifier,
                   const std::string& payload, uint8_t retryCount,
                   uint8_t alertsLimit, uint64_t nextRetryTime)
{
    bool updated = false;
    nlohmann::json root;

    try
    {
        if (std::filesystem::exists(tasksConfFile))
        {
            std::ifstream in(tasksConfFile);
            if (in.good())
            {
                in >> root;
            }
        }
        else
        {
            /* Create new file with empty slots */
            root = nlohmann::json::array();
            for (uint8_t i = 0; i < alertsLimit; ++i)
            {
                root.push_back({{"id", i},
                                {"alertType", ""},
                                {"identifier", ""},
                                {"payload", ""},
                                {"retryCount", 0},
                                {"nextRetryTime", 0}});
            }
        }

        /* Find first empty slot */
        for (auto& entry : root)
        {
            if (entry["alertType"] == "" && entry["identifier"] == "" &&
                entry["payload"] == "" && entry["retryCount"] == 0)
            {
                entry["alertType"] = alertType;
                entry["identifier"] = identifier;
                entry["payload"] = payload;
                entry["retryCount"] = retryCount;
                entry["nextRetryTime"] = nextRetryTime;
                updated = true;
                break;
            }
        }

        if (updated)
        {
            std::string tempFile = std::string(tasksConfFile) + ".tmp";
            std::ofstream out(tempFile);
            if (!out.good())
            {
                phosphor::logging::log<phosphor::logging::level::ERR>(
                    "Failed to open temp file for writing");
                return false;
            }

            out << root.dump(4);
            out.close();

            if (!out.good())
            {
                phosphor::logging::log<phosphor::logging::level::ERR>(
                    "Failed to write to temp file");
                std::filesystem::remove(tempFile);
                return false;
            }

            std::filesystem::rename(tempFile, tasksConfFile);
            return true;
        }

        return false;
    }
    catch (const std::filesystem::filesystem_error& e)
    {
        phosphor::logging::log<phosphor::logging::level::ERR>(
            "Filesystem error in writeTaskData",
            phosphor::logging::entry("EXCEPTION=%s", e.what()));
        return false;
    }
    catch (const nlohmann::json::exception& e)
    {
        phosphor::logging::log<phosphor::logging::level::ERR>(
            "JSON error in writeTaskData",
            phosphor::logging::entry("EXCEPTION=%s", e.what()));
        return false;
    }
    catch (const std::exception& e)
    {
        phosphor::logging::log<phosphor::logging::level::ERR>(
            "Exception in writeTaskData",
            phosphor::logging::entry("EXCEPTION=%s", e.what()));
        return false;
    }
}

/**
 * @brief Add alert to retry queue
 *
 * @param alertType Type of alert
 * @param identifier Alert identifier
 * @param payload Alert payload
 * @return true if successful, false if queue is full
 */
bool addToMap(std::string alertType, std::string identifier,
              std::string payload)
{
    std::lock_guard<std::mutex> lock(alertMapMutex);

    /* Calculate next retry time */
    uint64_t currentTime = static_cast<uint64_t>(
        std::chrono::system_clock::to_time_t(std::chrono::system_clock::now()));
    uint64_t nextRetryTime = currentTime + timeInterval_g;

    for (uint8_t i = 0; i < alertsLimit_g; ++i)
    {
        if (alertMap[i].isEmpty())
        {
            alertMap[i] = {alertType, identifier, payload, retryCount_g,
                           nextRetryTime};
            bool isFileUpdated =
                writeTaskData(alertType, identifier, payload, retryCount_g,
                              alertsLimit_g, nextRetryTime);
            if (!isFileUpdated)
            {
                phosphor::logging::log<phosphor::logging::level::ERR>(
                    "Failed to write task data to file");
                alertMap[i] = {};
                return false;
            }
            return true;
        }
    }

    phosphor::logging::log<phosphor::logging::level::ERR>(
        "Alert queue is full, cannot add new alert");
    return false;
}

/**
 * @brief Process pending alert retry tasks
 *
 * Runs in a separate thread, checking every second for tasks that are ready
 * to retry. Uses fine-grained locking to avoid blocking D-Bus calls.
 */
void processTasks()
{
    phosphor::logging::log<phosphor::logging::level::INFO>(
        "Retry processing thread started");

    while (true)
    {
        try
        {
            /* Check every 1 second for responsiveness */
            std::this_thread::sleep_for(std::chrono::seconds(1));

            /* Skip if not configured */
            if (alertsLimit_g == 0)
            {
                continue;
            }

            /* Get current time */
            uint64_t currentTime =
                static_cast<uint64_t>(std::chrono::system_clock::to_time_t(
                    std::chrono::system_clock::now()));

            std::vector<std::pair<uint8_t, AlertData>> tasksToProcess;
            {
                std::lock_guard<std::mutex> lock(alertMapMutex);

                for (uint8_t i = 0; i < alertsLimit_g; ++i)
                {
                    if (alertMap.find(i) == alertMap.end() ||
                        alertMap[i].isEmpty())
                    {
                        continue;
                    }

                    auto& alert = alertMap[i];

                    /* Check if it's time to retry */
                    if (currentTime >= alert.nextRetryTime)
                    {
                        tasksToProcess.push_back({i, alert});
                    }
                }
            }

            for (auto& [id, alert] : tasksToProcess)
            {
                phosphor::logging::log<phosphor::logging::level::INFO>(
                    "Processing retry for alert");

                bool success = false;

                if (alert.alertType == "smtp")
                {
                    success = sendSMTPAlert(alert.identifier, alert.payload);
                }
                else if (alert.alertType == "snmp")
                {
                    success = sendSNMPAlert(alert.identifier, alert.payload);
                }
                else
                {
                    phosphor::logging::log<phosphor::logging::level::ERR>(
                        "Unknown alert type",
                        phosphor::logging::entry("TYPE=%s",
                                                 alert.alertType.c_str()));
                    success = false;
                }

                {
                    std::lock_guard<std::mutex> lock(alertMapMutex);

                    /* Verify task still exists */
                    if (alertMap.find(id) == alertMap.end() ||
                        alertMap[id].isEmpty())
                    {
                        continue;
                    }

                    if (success)
                    {
                        /* Success: Remove from queue */
                        phosphor::logging::log<phosphor::logging::level::INFO>(
                            "Alert sent successfully, removing from queue");

                        alertMap[id] = {};
                        removeEntryFromJson(id);
                    }
                    else if (alert.alertType != "smtp" &&
                             alert.alertType != "snmp")
                    {
                        /* Invalid type: Remove */
                        alertMap[id] = {};
                        removeEntryFromJson(id);
                    }
                    else
                    {
                        /* Failure: Schedule next retry or remove if exhausted
                         */
                        if (alertMap[id].retryCount > 0)
                        {
                            /* Schedule next retry */
                            alertMap[id].nextRetryTime =
                                currentTime + timeInterval_g;
                            alertMap[id].retryCount -= 1;

                            phosphor::logging::log<
                                phosphor::logging::level::WARNING>(
                                "Alert send failed, retries remaining");
                            updateEntryInJson(id, alertMap[id]);
                        }
                        else
                        {
                            /* Retry count exhausted */
                            phosphor::logging::log<
                                phosphor::logging::level::ERR>(
                                "Alert retry count exhausted, removing from "
                                "queue");

                            alertMap[id] = {};
                            removeEntryFromJson(id);
                        }
                    }
                }
            }
        }
        catch (const std::exception& e)
        {
            phosphor::logging::log<phosphor::logging::level::ERR>(
                "Exception in processTasks",
                phosphor::logging::entry("EXCEPTION=%s", e.what()));
        }
    }
}

/**
 * @brief Load pending tasks from JSON file on startup
 */
void loadTasksFromFile()
{
    try
    {
        std::ifstream in(tasksConfFile);
        if (!in.good())
        {
            phosphor::logging::log<phosphor::logging::level::ERR>(
                "Failed to open tasks config file for reading");
            return;
        }

        nlohmann::json root;
        in >> root;

        if (!root.is_array())
        {
            phosphor::logging::log<phosphor::logging::level::ERR>(
                "Invalid tasks config file format - expected array");
            return;
        }

        for (const auto& entry : root)
        {
            if (!entry.contains("id") || !entry.contains("alertType") ||
                !entry.contains("identifier") || !entry.contains("payload") ||
                !entry.contains("retryCount") ||
                !entry.contains("nextRetryTime"))
            {
                phosphor::logging::log<phosphor::logging::level::WARNING>(
                    "Skipping incomplete task entry");
                continue;
            }

            uint8_t id = entry["id"].get<uint8_t>();
            std::string alertType = entry["alertType"].get<std::string>();
            std::string identifier = entry["identifier"].get<std::string>();
            std::string payload = entry["payload"].get<std::string>();
            uint8_t retryCount = entry["retryCount"].get<uint8_t>();
            uint64_t nextRetryTime = entry["nextRetryTime"].get<uint64_t>();

            /* Only load non-empty & valid entries */
            if ((!alertType.empty() || !identifier.empty() ||
                 !payload.empty() || retryCount != 0) &&
                (alertType == "smtp" || alertType == "snmp") &&
                (retryCount > 0 && retryCount <= MAX_RETRY))
            {
                alertMap[id] = {alertType, identifier, payload, retryCount,
                                nextRetryTime};
            }
        }

        phosphor::logging::log<phosphor::logging::level::INFO>(
            "Successfully loaded tasks from file");
    }
    catch (const nlohmann::json::exception& e)
    {
        phosphor::logging::log<phosphor::logging::level::ERR>(
            "JSON parse error while loading tasks",
            phosphor::logging::entry("EXCEPTION=%s", e.what()));
    }
    catch (const std::exception& e)
    {
        phosphor::logging::log<phosphor::logging::level::ERR>(
            "Exception while loading tasks from file",
            phosphor::logging::entry("EXCEPTION=%s", e.what()));
    }
}

void getRetryConf()
{
    try
    {
        constexpr auto retryConfFile =
            "/var/lib/pef-alert-manager/retryConf.json";

        std::ifstream in(retryConfFile);
        if (!in.good())
        {
            phosphor::logging::log<phosphor::logging::level::ERR>(
                "Failed to open retryConf.json");
            return;
        }
        nlohmann::json root;
        in >> root;

        retryCount_g = root.value("retryCount", 0);
        alertsLimit_g = root.value("alertsLimit", 0);
        timeInterval_g = root.value("timeInterval", 0);
    }
    catch (const nlohmann::json::exception& e)
    {
        phosphor::logging::log<phosphor::logging::level::ERR>(
            "JSON error in getRetryConf",
            phosphor::logging::entry("EXCEPTION=%s", e.what()));
    }
    catch (const std::exception& e)
    {
        phosphor::logging::log<phosphor::logging::level::ERR>(
            "Exception in getRetryConf",
            phosphor::logging::entry("EXCEPTION=%s", e.what()));
    }
}

PefImpl::PefImpl(sdbusplus::bus_t& bus, const char* path) :
    sdbusplus::server::xyz::openbmc_project::pendtask::Pef(bus, path), bus(bus)
{}

bool PefImpl::retryAlert(std::string alertType, std::string identifier,
                         std::string payload)
{
    try
    {
        /* Get retry configuration from D-Bus properties */
        getRetryConf();

        if (alertsLimit_g == 0 || timeInterval_g == 0 || retryCount_g == 0)
        {
            phosphor::logging::log<phosphor::logging::level::ERR>(
                "retryAlert: Configuration not initialized from D-Bus");
            return false;
        }
        if (alertType == "smtp" || alertType == "snmp")
        {
            return addToMap(alertType, identifier, payload);
        }
        else
        {
            phosphor::logging::log<phosphor::logging::level::ERR>(
                "retryAlert: Invalid AlertType",
                phosphor::logging::entry("ALERT_TYPE=%s", alertType.c_str()));
            return false;
        }
    }
    catch (const nlohmann::json::exception& e)
    {
        phosphor::logging::log<phosphor::logging::level::ERR>(
            "JSON parse error in retryAlert",
            phosphor::logging::entry("EXCEPTION=%s", e.what()));
        return false;
    }
    catch (const sdbusplus::exception_t& e)
    {
        phosphor::logging::log<phosphor::logging::level::ERR>(
            "D-Bus exception in retryAlert",
            phosphor::logging::entry("EXCEPTION=%s", e.what()));
        return false;
    }
    catch (const std::exception& e)
    {
        phosphor::logging::log<phosphor::logging::level::ERR>(
            "General exception in retryAlert",
            phosphor::logging::entry("EXCEPTION=%s", e.what()));
        return false;
    }
}

int main()
{
    /* Load any pending tasks from previous session */
    if (std::filesystem::exists(tasksConfFile))
    {
        loadTasksFromFile();
    }

    /* Initialize D-Bus */
    auto bus = sdbusplus::bus::new_default();
    bus.request_name("xyz.openbmc_project.Pendtask");
    PefImpl pef(bus, "/xyz/openbmc_project/Pendtask/pef");

    /* Start retry processing thread */
    std::thread taskThread(processTasks);
    taskThread.detach();

    /* Main D-Bus event loop */
    while (true)
    {
        bus.process_discard();
        bus.wait();
    }

    return 0;
}
