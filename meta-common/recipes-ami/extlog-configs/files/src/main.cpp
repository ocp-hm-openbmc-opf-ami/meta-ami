#include "include/main.hpp"

#include <sdbusplus/bus.hpp>
#include <sdbusplus/sdbus.hpp>
#include <sdeventplus/event.hpp>

#include <iostream>

int main(int /*argc*/, char* /*argv*/[])
{
    auto bus = sdbusplus::bus::new_default();
    bus.request_name(extlogconfbus);

    if (!loadJsonFromFile(ExtlogJsonFilePath))
    {
        return 1;
    }

    sdbusplus::server::manager_t objManager(bus, extlogconfigObjPath);
    ExtlogConfigsImp extlogconfigs(bus, extlogconfigObjPath);

    extlogconfigs.enableExtlog(extlogconfig["EnableExtlog"]);
    extlogconfigs.logLevel(extlogconfig["LogLevel"]);
    extlogconfigs.reqResLogLevel(extlogconfig["ReqResLogLevel"]);

    bus.process_loop();

    return -1;
}
