#pragma once

#include <sdbusplus/bus.hpp>
#include <xyz/openbmc_project/Pendtask/pef/server.hpp>

#include <string>
#include <vector>
#define MAX_ALERTS_LIMIT 100
#define MAX_RETRY 10
#define MAX_INTERVAL 3600 /* seconds */

/* Mail alert service configuration */
constexpr const char* mailService = "xyz.openbmc_project.mail";
constexpr const char* mailObjPath = "/xyz/openbmc_project/mail/alert";
constexpr const char* mailIface = "xyz.openbmc_project.mail.alert";
constexpr const char* sendMailMethod = "SendMail";

constexpr const char* tasksConfFile =
    "/var/lib/pef-alert-manager/pendtasks.json";

/**
 * @class PefImpl
 * @brief Implementation of PEF (Platform Event Filtering) retry alert interface
 *
 * This class manages the retry logic for failed alert notifications.
 * It queues failed alerts and retries them at configured intervals.
 */
class PefImpl : public sdbusplus::server::xyz::openbmc_project::pendtask::Pef
{
  public:
    /**
     * @brief Constructor
     * @param bus D-Bus connection
     * @param path D-Bus object path
     */
    PefImpl(sdbusplus::bus_t& bus, const char* path);

    /**
     * @brief Add an alert to the retry queue
     *
     * Queues an alert for retry processing. The alert will be retried
     * at intervals specified by timeInterval until it succeeds or
     * retryCount is exhausted.
     *
     * @param alertType Type of alert ("smtp" or "snmp")
     * @param identifier Unique identifier for the alert
     * @param payload Alert payload data
     *
     * @return true if alert was successfully queued, false otherwise
     */
    bool retryAlert(std::string alertType, std::string identifier,
                    std::string payload) override;

  private:
    sdbusplus::bus_t& bus;
};

/**
 * @brief Process pending alert retry tasks
 *
 * This function runs in a separate thread and processes all pending
 * alerts at configured intervals. It attempts to send each queued alert
 * and manages retry counts.
 */
void processTasks();
