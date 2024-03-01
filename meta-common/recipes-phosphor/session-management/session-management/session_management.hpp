/* ****************************************************************
 *
 * Session Management
 * Filename : session_management.hpp
 *
 * @brief Implementation of session management
 *
 * Author: Krishna Raj krishnar@ami.com
 *
 *****************************************************************/

#include <string.h>

#include <iostream>
#include <map>
#include <sdbusplus/asio/object_server.hpp>

static constexpr const char* sessionMgrObj =
    "/xyz/openbmc_project/SessionManager";
static constexpr const char* sessionDbusNmae =
    "xyz.openbmc_project.SessionManager";
static constexpr const char* interfaceKvm =
    "xyz.openbmc_project.SessionManager.Kvm";
static constexpr const char* interfaceWeb =
    "xyz.openbmc_project.SessionManager.Web";
static constexpr const char* interfaceVmedia =
    "xyz.openbmc_project.SessionManager.Vmedia";

static constexpr const char* kvmService = "start-ipkvm.service";
static constexpr const char* vmediaService =
    "xyz.openbmc_project.VirtualMedia.service";
static constexpr const char* webService = "bmcweb.service";

std::shared_ptr<sdbusplus::asio::dbus_interface> kvmIface;
std::shared_ptr<sdbusplus::asio::dbus_interface> webIface;
std::shared_ptr<sdbusplus::asio::dbus_interface> vmediaIface;

using sessionInfo =
    std::tuple<uint16_t, std::string, std::string, uint8_t, uint8_t, uint8_t>;
constexpr auto reasonLogout = 0x01;
constexpr auto reasonExpiry = 0x02;
constexpr auto reasonUnknown = 0x03;
constexpr auto maxSessionType = 2;

enum sessionType
{
    KVM = 0,
    WEB = 1,
    VMEDIA = 2
};
const std::map<uint8_t, std::string> validPriv = {{0x1, "Callback"},
                                                  {0x2, "User"},
                                                  {0x3, "Operator"},
                                                  {0x4, "Administrator"},
                                                  {0x5, "OEM Proprietary"}};

class SessionMgr
{

  public:
    SessionMgr(sdbusplus::asio::object_server& objserver) : server(objserver)
    {
        addKvmInterface(server);
        addWebInterface(server);
        addVmediaInterface(server);
    }
    void addKvmInterface(sdbusplus::asio::object_server& server)
    {
        kvmIface = server.add_interface(sessionMgrObj, interfaceKvm);
        kvmIface->register_property("KvmSessionInfo", data);
        kvmIface->initialize();
    }
    void addWebInterface(sdbusplus::asio::object_server& server)
    {
        webIface = server.add_interface(sessionMgrObj, interfaceWeb);
        webIface->register_property("WebSessionInfo", data);
        webIface->initialize();
    }
    void addVmediaInterface(sdbusplus::asio::object_server& server)
    {
        vmediaIface = server.add_interface(sessionMgrObj, interfaceVmedia);
        vmediaIface->register_property("VmediaSessionInfo", data);
        vmediaIface->initialize();
    }

  private:
    std::vector<sessionInfo> data;
    sdbusplus::asio::object_server& server;
};

bool findAndRemove(std::vector<sessionInfo>& data, uint8_t sessionId)
{

    bool found = false;

    for (auto itr = data.begin(); itr != data.end(); ++itr)
    {
        if (std::get<0>(*itr) == sessionId)
        {
            itr = data.erase(itr);
            found = true;
            break;
        }
    }
    return found;
}
