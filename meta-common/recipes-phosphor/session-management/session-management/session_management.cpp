
/* ****************************************************************
 *
 * Session Management
 * Filename : session_management.cpp
 *
 * @brief Implementation of session management
 *
 * Author: Krishna Raj krishnar@ami.com
 *
 *****************************************************************/

#include <boost/asio/io_context.hpp>
#include <iostream>
#include <sdbusplus/asio/connection.hpp>
#include <session_management.hpp>
#include <tuple>
#include <vector>

static std::vector<sessionInfo> kvmSessionInfo;
static std::vector<sessionInfo> webSessionInfo;
static std::vector<sessionInfo> vmediaSessionInfo;
static uint16_t Id = 0;

/** @brief Implementation for SessionUnregister
 *  This dbus method unregister session information based on sessionId
 *
 *  @param[in] sessionId - Unique identifier for the session
 *  @param[in] sessionType - Session type used for login
 *  @param[in] reason - reason for unregister the session
 *
 *  @return rsp[bool] - success or failure
 */

bool sessionUnregister(uint8_t sessionId, uint8_t sessionType, int reason)
{

    if (!(sessionType <= maxSessionType) ||
        !(reasonLogout == reason || reasonExpiry == reason ||
          reasonUnknown == reason))
    {
        std::cerr << "Invalid argument \n";
        return false;
    }

    switch (sessionType)
    {
        case sessionType::KVM:
            if (findAndRemove(kvmSessionInfo, sessionId))
            {
                if (kvmIface &&
                    !(kvmIface->set_property("KvmSessionInfo", kvmSessionInfo)))
                {
                    std::cerr << "error kvm setting State \n";
                    return false;
                }
            }
            else
            {
                std::cerr << "Couldn't find specfifed Session Id info \n";
                return false;
            }
            break;
        case sessionType::WEB:
            if (findAndRemove(webSessionInfo, sessionId))
            {
                if (webIface &&
                    !(webIface->set_property("WebSessionInfo", webSessionInfo)))
                {
                    std::cerr << "error setting web State \n";
                    return false;
                }
            }
            else
            {
                std::cerr << "Couldn't find specfifed Session Id info \n";
                return false;
            }

            break;
        case sessionType::VMEDIA:
            if (findAndRemove(vmediaSessionInfo, sessionId))
            {
                if (vmediaIface && !(vmediaIface->set_property(
                                       "VmediaSessionInfo", vmediaSessionInfo)))
                {
                    std::cerr << "error setting vmedia State \n";
                    return false;
                }
            }
            else
            {
                std::cerr << "Couldn't find specfifed Session Id info \n";
                return false;
            }
            break;
    }
    return true;
}

/** @brief Implementation for SessionRegister
 *  This dbus method add new session info to properties.
 *
 *  @param[in] sessionId - Holds the value of session id that is used to
 * uniquely identify a session record.
 *  @param[in] ipAdress - IP address of the client
 *  @param[in] userName - Name of the user who is trying to access the BMC
 *  @param[in] sessionType - Session type used for login
 *  @param[in] previlage - User privilage
 *  @param[in] userId - user Id
 *
 *  @return rsp[bool] - success or failure
 */

bool sessionRegister(uint8_t sessionId, std::string ipAdress,
                     std::string userName, uint8_t sessionType,
                     uint8_t previlage, uint8_t userId)
{
    sessionInfo temp;
    if (sessionId == 0 && (sessionType <= maxSessionType) &&
        (validPriv.find(previlage) != validPriv.end()))
    {
        Id++;
        temp =
            make_tuple(Id, ipAdress, userName, sessionType, previlage, userId);
    }
    else
    {
        std::cerr << "Invalid Argument\n";
        return false;
    }
    switch (sessionType)
    {
        case sessionType::KVM:
            kvmSessionInfo.push_back(temp);
            if (kvmIface &&
                !(kvmIface->set_property("KvmSessionInfo", kvmSessionInfo)))
            {
                Id--;
                std::cerr << "error kvm setting State \n";
                return false;
            }
            break;
        case sessionType::WEB:
            webSessionInfo.push_back(temp);
            if (webIface &&
                !(webIface->set_property("WebSessionInfo", webSessionInfo)))
            {
                Id--;
                std::cerr << "error setting web State \n";
                return false;
            }
            break;
        case sessionType::VMEDIA:
            vmediaSessionInfo.push_back(temp);
            if (vmediaIface && !(vmediaIface->set_property("VmediaSessionInfo",
                                                           vmediaSessionInfo)))
            {
                Id--;
                std::cerr << "error setting VMEDIA State \n";
                return false;
            }
            break;
    }
    return true;
}

/**
 * \brief Callback function for handeling crashes
 */

inline static sdbusplus::bus::match_t
    crashErrorEventMonitor(std::shared_ptr<sdbusplus::asio::connection> conn)
{

    auto crashEventMatcherCallback = [conn](sdbusplus::message_t& msg) {
        uint32_t jobID{};
        sdbusplus::message::object_path jobPath;
        std::string jobUnit{};
        std::string jobResult{};
        msg.read(jobID, jobPath, jobUnit, jobResult);
        std::string test = jobPath.str;

        if (jobResult == "failed")
        {
            if (jobUnit == kvmService)
            {
                kvmSessionInfo.clear();
                if (kvmIface &&
                    !(kvmIface->set_property("KvmSessionInfo", kvmSessionInfo)))
                {
                    std::cerr << "error KVM setting State \n";
                }
            }
            if (jobUnit == webService)
            {
                webSessionInfo.clear();
                if (webIface &&
                    !(webIface->set_property("WebSessionInfo", webSessionInfo)))
                {
                    std::cerr << "error setting WEB State \n";
                }
            }
            if (jobUnit == vmediaService)
            {
                vmediaSessionInfo.clear();
                if (vmediaIface && !(vmediaIface->set_property(
                                       "VmediaSessionInfo", vmediaSessionInfo)))
                {
                    std::cerr << "error setting VMEDIA State \n";
                }
            }
        }
    };

    sdbusplus::bus::match_t crashEventMatcher(
        static_cast<sdbusplus::bus_t&>(*conn),
        "type='signal',interface='org.freedesktop.systemd1.Manager',"
        "member='JobRemoved'",
        std::move(crashEventMatcherCallback));

    return crashEventMatcher;
}

int main()
{

    // setup connection to dbus
    boost::asio::io_context io;
    auto conn = std::make_shared<sdbusplus::asio::connection>(io);

    // object server
    conn->request_name("xyz.openbmc_project.SessionManager");
    auto server = sdbusplus::asio::object_server(conn);

    std::shared_ptr<sdbusplus::asio::dbus_interface> iface =
        server.add_interface(sessionMgrObj, sessionDbusNmae);

    iface->register_method(
        "SessionRegister",
        [](uint8_t sessionId, std::string ipAdress, std::string userName,
           uint8_t sessionType, uint8_t previlage, uint8_t userId) {
            bool response = sessionRegister(sessionId, ipAdress, userName,
                                            sessionType, previlage, userId);
            return response;
        });

    iface->register_method(
        "SessionUnregister",
        [](uint8_t sessionId, uint8_t sessionType, int reason) {
            bool response = sessionUnregister(sessionId, sessionType, reason);
            return response;
        });
    SessionMgr obj(server);
    iface->initialize();

    sdbusplus::bus::match_t crashEventMonitor = crashErrorEventMonitor(conn);
    io.run();

    return 0;
}
