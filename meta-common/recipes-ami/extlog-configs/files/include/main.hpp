
#include <boost/asio/io_context.hpp>
#include <nlohmann/json.hpp>
#include <phosphor-logging/elog-errors.hpp>
#include <phosphor-logging/elog.hpp>
#include <phosphor-logging/lg2.hpp>
#include <phosphor-logging/log.hpp>
#include <sdbusplus/asio/connection.hpp>
#include <sdbusplus/asio/object_server.hpp>
#include <xyz/openbmc_project/Common/error.hpp>
#include <xyz/openbmc_project/Extlog/ExtlogConfigs/server.hpp>

#include <fstream>

using namespace phosphor::logging;
using json = nlohmann::json;
json extlogconfig;
const std::string ExtlogJsonFilePath = "/etc/extlog-configs/extlogconfig.json";

static constexpr const char* extlogconfbus = "xyz.openbmc_project.Extlog";
static constexpr const char* extlogconfigObjPath =
    "/xyz/openbmc_project/Extlog/ExtlogConfigs";

using IfcBase = sdbusplus::xyz::openbmc_project::Extlog::server::ExtlogConfigs;
using InvalidArgument =
    sdbusplus::xyz::openbmc_project::Common::Error::InvalidArgument;
using Argument = xyz::openbmc_project::Common::InvalidArgument;

int updateJson()
{
    if (std::ofstream ofs(ExtlogJsonFilePath); ofs.is_open())
    {
        ofs << std::setw(4) << extlogconfig << std::endl;
        ofs.close();
    }
    else
    {
        return -1;
    }
    return 0;
}

bool loadJsonFromFile(const std::string& filePath)
{
    std::ifstream ifs(filePath);
    if (!ifs.is_open())
    {
        lg2::error("Error opening JSON file: {FILE}", "FILE", filePath);
        return false;
    }

    try
    {
        ifs >> extlogconfig;
        ifs.close();
    }
    catch (const json::exception& e)
    {
        lg2::error("Error parsing JSON: {ERR}", "ERR", e);
        return false;
    }

    return true;
}

class ExtlogConfigsImp : public IfcBase
{
  public:
    /* Define all of the basic class operations:
     *     Not allowed:
     *         - Default constructor to avoid nullptrs.
     *         - Copy operations due to internal unique_ptr.
     *         - Move operations due to 'this' being registered as the
     *           'context' with sdbus.
     *     Allowed:
     *         - Destructor.
     */
    ExtlogConfigsImp() = delete;
    ExtlogConfigsImp(const ExtlogConfigsImp&) = delete;
    ExtlogConfigsImp& operator=(const ExtlogConfigsImp&) = delete;
    ExtlogConfigsImp(ExtlogConfigsImp&&) = delete;
    ExtlogConfigsImp& operator=(ExtlogConfigsImp&&) = delete;
    virtual ~ExtlogConfigsImp() = default;

    /** @brief Constructor to put object onto bus at a dbus path.
     *  @param[in] bus - Bus to attach to.
     *  @param[in] path - Path to attach at.
     */
    ExtlogConfigsImp(sdbusplus::bus_t& bus, const char* path) :
        IfcBase(bus, path)
    {}

    virtual bool enableExtlog(bool value)
    {
        if (value == IfcBase::enableExtlog())
        {
            return value;
        }
        extlogconfig["EnableExtlog"] = value;
        IfcBase::enableExtlog(value);
        updateJson();
        return value;
    }

    uint8_t logLevel(uint8_t value) override
    {
        if (value > 1)
        {
            lg2::error("Fail to set logLevel");
            elog<InvalidArgument>(Argument::ARGUMENT_NAME("logLevel"),
                                  Argument::ARGUMENT_VALUE("error"));
            return 0;
        }
        if (value == IfcBase::logLevel())
        {
            return value;
        }
        extlogconfig["LogLevel"] = value;
        IfcBase::logLevel(value);
        updateJson();
        return value;
    }
    uint8_t reqResLogLevel(uint8_t value) override
    {
        if (value > 2)
        {
            lg2::error("Fail to set reqResLogLevel");
            elog<InvalidArgument>(Argument::ARGUMENT_NAME("reqResLogLevel"),
                                  Argument::ARGUMENT_VALUE("error"));
            return 0;
        }
        if (value == IfcBase::reqResLogLevel())
        {
            return value;
        }
        extlogconfig["ReqResLogLevel"] = value;
        IfcBase::reqResLogLevel(value);
        updateJson();
        return value;
    }
};
