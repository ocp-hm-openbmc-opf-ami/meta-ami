#include <gpioCallbackHandler.hpp>

#include <iostream>

/*---------------------------------------------------------------------------
 * @fn testInterruptHandler
 *
 * @brief This sample function has been added to demonstrate functionality.
 *        It will print a log message whenever the Callback handler is invoked.
 *---------------------------------------------------------------------------*/
void gpioInterruptHandler(std::string GpioName, std::string EventMon)
{
    std::cout << "TestInterrupt::" << GpioName << ", " << EventMon << std::endl;
}

/*---------------------------------------------------------------------------
 * @fn powerOff
 *
 * @brief This function performs a power-off operation.
 *---------------------------------------------------------------------------*/
void powerOff([[maybe_unused]] std::string GpioName,
              [[maybe_unused]] std::string EventMon)
{
    // Create a connection to the system bus
    auto conn = sdbusplus::bus::new_default();
    auto method = conn.new_method_call(pwrService, pwrStateObjPath, PROP_INTF,
                                       METHOD_SET);
    method.append(pwrStateIface, "RequestedPowerTransition");
    method.append(std::variant<std::string>(pwrCtlOff));

    auto reply = conn.call(method);

    if (reply.is_method_error())
    {
        phosphor::logging::log<phosphor::logging::level::ERR>(
            "Failed to set RequestedPowerTransition poweroff");
    }
}

/*---------------------------------------------------------------------------
 * @fn addIpmiSel
 *
 * @brief This function logs the event as an IPMI SEL entry.
 *---------------------------------------------------------------------------*/
void addIpmiSel([[maybe_unused]] std::string GpioName,
                [[maybe_unused]] std::string EventMon)
{
    // Create a connection to the system bus
    auto conn = sdbusplus::bus::new_default();

    std::string ipmiSELAddMessage = "IPMI generated SEL Entry";
    std::string sensorPath = "";
    /**
     *According to the IPMI specification, the SEL (System Event Log) record
     *format can include up to three Event Data fields. For detailed
     *descriptions of each Event Data field, please refer to Section 29.7 of the
     *IPMI specification.
     **/
    std::vector<uint8_t> eventData(
        selEvtDataMaxSize, 0xFF); // 3 bytes of event data initialized to 0xFF
    bool assert = true;
    std::map<std::string, std::string> addData{};
    /*
       Fill required parameter
       addData["SENSOR_DATA"] = ;
       addData["SENSOR_PATH"] = ;
       addData["EVENT_DIR"] = ;
       addData["GENERATOR_ID"] = ;
       addData["RECORD_TYPE"] = ;
       addData["SENSOR_TYPE"] = ;
       addData["EVENT_TYPE"] = ;
*/

    // Log SEL event
    auto method = conn.new_method_call(ipmiService, ipmiObjPath, ipmiIntf,
                                       ipmiSelAddMethod);
    method.append(ipmiSELAddMessage, sensorPath, eventData, assert, selBMCGenID,
                  addData);
    try
    {
        auto reply = conn.call(method);
    }
    catch (sdbusplus::exception_t&)
    {
        std::cerr << "error adding SEL Event for " << sensorPath << "\n";
    }
}

/*---------------------------------------------------------------------------
 * @fn hostReset
 *
 * @brief This function performs a host rest operation.
 *---------------------------------------------------------------------------*/
void hostReset([[maybe_unused]] std::string GpioName,
               [[maybe_unused]] std::string EventMon)
{
    // Create a connection to the system bus
    auto conn = sdbusplus::bus::new_default();
    auto method =
        conn.new_method_call(hostService, hostStatePath, PROP_INTF, METHOD_SET);
    method.append(hostStateIntf, "RequestedHostTransition");
    method.append(std::variant<std::string>(reset));

    auto reply = conn.call(method);

    if (reply.is_method_error())
    {
        phosphor::logging::log<phosphor::logging::level::ERR>(
            "Failed to set RequestedHostTransition");
    }
}
