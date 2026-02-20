#pragma once
#include <boost/asio.hpp>
#include <boost/asio/io_context.hpp>
#include <boost/asio/io_service.hpp>
#include <phosphor-logging/log.hpp>
#include <sdbusplus/asio/connection.hpp>
#include <sdbusplus/asio/object_server.hpp>
#include <sdbusplus/bus.hpp>

#include <functional>
#include <iostream>
#include <map>
#include <variant>

// Callback Function Declaration
void gpioInterruptHandler(std::string, std::string);
void powerOff(std::string, std::string);
void addIpmiSel(std::string, std::string);
void hostReset(std::string, std::string);

// Callback Registration
inline std::map<std::string, std::function<void(std::string, std::string)>>
    callbackHook = {

        /** { "Callback name is configured in JSON",
         * Callback accepts two parameters(string, string)}
         */
        {"TestInterrupt", gpioInterruptHandler}

};

// Dbus
constexpr auto PROP_INTF = "org.freedesktop.DBus.Properties";
constexpr auto METHOD_SET = "Set";

/* power service ,objectpath,interface */
static constexpr const char* pwrService = "xyz.openbmc_project.State.Chassis";
static constexpr const char* pwrStateObjPath =
    "/xyz/openbmc_project/state/chassis0";
static constexpr const char* pwrStateIface =
    "xyz.openbmc_project.State.Chassis";
static constexpr const char* pwrCtlOff =
    "xyz.openbmc_project.State.Chassis.Transition.Off";
static constexpr const char* hostService = "xyz.openbmc_project.State.Host0";
static constexpr const char* hostStatePath = "/xyz/openbmc_project/state/host0";
static constexpr const char* hostStateIntf = "xyz.openbmc_project.State.Host";
static constexpr const char* reset =
    "xyz.openbmc_project.State.Host.Transition.ForceWarmReboot";

// IPMI Sel
static constexpr const char* ipmiService = "xyz.openbmc_project.Logging.IPMI";
static constexpr const char* ipmiObjPath = "/xyz/openbmc_project/Logging/IPMI";
static constexpr const char* ipmiIntf = "xyz.openbmc_project.Logging.IPMI";
static constexpr const char* ipmiSelAddMethod = "IpmiSelAdd";
static constexpr uint16_t selBMCGenID = 0x0020;
static constexpr size_t selEvtDataMaxSize = 3;
