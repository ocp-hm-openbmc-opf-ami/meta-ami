#include <iostream>
#include <sdbusplus/bus.hpp>
#include <vector>
#include <thread>
#include <chrono>
#include <algorithm>
#include <variant> 
#include <sdbusplus/bus/match.hpp>
#include <sdbusplus/message.hpp>
#include <map>
#include <string>
#include <regex>
#include <pwd.h>
#include <csignal> 

enum class UnregisterReason {
    LOGOUT_SESSION = 1,
    LOGOUT_EXPIRY,
    TERMINATED_UNEXPECTEDLY
};

struct SessionInfo {
    uint8_t sessionId;
    std::string ipAddress;
    std::string username;
    uint8_t sessionType;
    uint8_t privilege;
    uint8_t userId;
    std::string mountType;
};

std::map<std::string, SessionInfo> serviceSessions;
std::vector<SessionInfo> sshSessionInfoProperty;

constexpr int monitorTriggersDelay = 3;

using SshSessionInfoEntry = std::tuple<uint8_t, std::string, std::string, uint8_t, uint8_t, uint8_t, std::string>;
using SshSessionInfoType = std::vector<SshSessionInfoEntry>;

const char* systemdService = "org.freedesktop.systemd1";
const char* systemdPath = "/org/freedesktop/systemd1";
const char* managerInterface = "org.freedesktop.systemd1.Manager";

const char* dbusPropertyInterface = "org.freedesktop.DBus.Properties";
const char* serviceInterface = "org.freedesktop.systemd1.Service";

const char* userManagerService = "xyz.openbmc_project.User.Manager";
const char* userAttributeInterface = "xyz.openbmc_project.User.Attributes";
const char* userObjpath = "/xyz/openbmc_project/user/";

const char* sessionMgrservice = "xyz.openbmc_project.SessionManager";
const char* sessionMgrobjpath =  "/xyz/openbmc_project/SessionManager" ;
const char* sessionMgrInterface = "xyz.openbmc_project.SessionManager" ;
const char* sessionMgrSSHInterface =  "xyz.openbmc_project.SessionManager.Ssh";
SshSessionInfoType sessionInfoList;

uint8_t mapPrivilegeToLevel(const std::string& privilege) {
    if (privilege == "priv-admin") return 4;
    if (privilege == "priv-operator") return 3;
    if (privilege == "priv-user") return 2;
    return 0; 
}

void deregisterService(const std::string& serviceName);

bool stopService(const std::string& serviceName) {

    try {
        auto bus = sdbusplus::bus::new_system();
        auto stopMethod = bus.new_method_call(systemdService, systemdPath, managerInterface, "StopUnit");
        stopMethod.append(serviceName, "replace");
        bus.call(stopMethod);
        return true;
    }
    catch (const sdbusplus::exception::SdBusError& ex) {
        std::cerr << "Failed to stop service " << serviceName << ": " << ex.what() << std::endl;
        return false;
    }
}


std::string extractClientIP(const std::string& serviceName) {
    std::regex ipRegex(R"(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}:\d{1,5}-(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}))");
    std::smatch match;
    
    if (std::regex_search(serviceName, match, ipRegex)) {
        return match[1]; 
    }

    return "";
}

SessionInfo getServiceSessionInfo(const std::string& serviceName) 
{
    SessionInfo sessionInfo = {0, "", "", 0, 0, 0, ""};
    sdbusplus::message::object_path path;

    try {
        auto bus = sdbusplus::bus::new_system();

        auto method = bus.new_method_call(systemdService, systemdPath,
                managerInterface, "GetUnit");
        method.append(serviceName);
        auto reply = bus.call(method);

        reply.read(path);
        std::string uintpath = static_cast<std::string>(path);

        auto showMethod = bus.new_method_call(systemdService, uintpath.c_str(), dbusPropertyInterface, "Get");
        showMethod.append(serviceInterface, "MainPID");

        std::variant<uint32_t>  mainPID;
        sdbusplus::message::message showResponse = bus.call(showMethod);
        showResponse.read(mainPID);
        uint32_t PID = std::get<uint32_t>(mainPID);

        std::string pidPath = "/proc/" + std::to_string(PID) + "/status";
        FILE* file = fopen(pidPath.c_str(), "r");
        if (file) {
            char line[256];
            while (fgets(line, sizeof(line), file)) {
                if (strncmp(line, "Uid:", 4) == 0) {
                    unsigned int uid;
                    sscanf(line, "Uid:\t%u", &uid);
                    sessionInfo.userId = static_cast<uint8_t>(uid);
                    break;
                }
            }
            fclose(file);
        }

        struct passwd* pw = getpwuid(sessionInfo.userId);
        if (pw) {
            sessionInfo.username = pw->pw_name;
        } else {
            std::cerr << "Failed to get username for UID: " << sessionInfo.userId << std::endl;
        }

        sessionInfo.ipAddress = extractClientIP(serviceName);

        std::string userObjPath = userObjpath + sessionInfo.username;

        auto privilegeMethod = bus.new_method_call(
                userManagerService,
                userObjPath.c_str(),
                dbusPropertyInterface,
                "Get"
                );
        privilegeMethod.append(userAttributeInterface, "UserPrivilege");

        std::variant<std::string> varPrivilegeStr;
        std::string PrivilegeStr;
        sdbusplus::message::message privilegeResponse = bus.call(privilegeMethod);
        privilegeResponse.read(varPrivilegeStr);
        PrivilegeStr = std::get<std::string>(varPrivilegeStr);
        sessionInfo.privilege = mapPrivilegeToLevel(PrivilegeStr);
    }
    catch (const sdbusplus::exception::SdBusError& ex) {
        std::cerr << "Error: " << ex.what() << std::endl;
    }

    return sessionInfo;
}

SshSessionInfoType getDbusProperty(sdbusplus::bus::bus& bus) {
    SshSessionInfoType sessionInfoList;

    try {
        auto method = bus.new_method_call(
            sessionMgrservice,  
            sessionMgrobjpath,
            dbusPropertyInterface,   
            "Get");                           

        method.append(sessionMgrSSHInterface, "SshSessionInfo");

        sdbusplus::message::message response = bus.call(method);

        std::variant<SshSessionInfoType> result;
        response.read(result);

        sessionInfoList = std::get<SshSessionInfoType>(result);

    } catch (const std::exception& e) {
        std::cerr << "Error retrieving D-Bus property: " << e.what() << std::endl;
    }

    return sessionInfoList;
}


void compareSessionInfos(SshSessionInfoType& sshSessionInfos) {

    std::this_thread::sleep_for(std::chrono::seconds(1));
    std::string serviceName; 
    if (sshSessionInfos == sessionInfoList) {
        std::cout << "Both session lists are the same. Skipping assignment." << std::endl;
        return; 
    }

    for (const auto& entry : sshSessionInfos) {

        bool valid = false;
        if (std::find(sessionInfoList.begin(), sessionInfoList.end(), entry) == sessionInfoList.end()) {

            for (const auto& serviceEntry : serviceSessions) {
                if (serviceEntry.second.sessionId == std::get<0>(entry)) {
                    valid = true;
                    serviceName = serviceEntry.first;
                }
            }
            if(!valid)
            {
                try{
                    auto bus = sdbusplus::bus::new_default();
                    auto method = bus.new_method_call(sessionMgrservice,
                            sessionMgrobjpath,
                            sessionMgrInterface,
                            "SessionUnregister");

                    method.append(std::get<0>(entry), std::get<3>(entry), static_cast<int>(UnregisterReason::TERMINATED_UNEXPECTEDLY));

                    sdbusplus::message::message response = bus.call(method);
                    bool success;
                    response.read(success);
                    if(success)
                    {
                        std::cout << "successfully deregister the unrunning service" << std::endl;
                    }

                }
                catch (const std::exception& e) {
                    std::cerr << "Error registering service " << serviceName << ": " << e.what() << std::endl;
                }
            } 

        }
    }

    for (const auto& entry : sessionInfoList) {
        if (std::find(sshSessionInfos.begin(), sshSessionInfos.end(), entry) == sshSessionInfos.end()) {
            for (const auto& serviceEntry : serviceSessions) {
                if (serviceEntry.second.sessionId == std::get<0>(entry)) {
                    stopService(serviceEntry.first);
                }
            }
        }
    }

    sessionInfoList = sshSessionInfos;
}


void handleSshSessionInfoSignal(sdbusplus::message::message& msg) {
    std::string interface;
    std::map<std::string, std::variant<SshSessionInfoType>> properties;

    msg.read(interface, properties);
    SshSessionInfoType sshSessionInfos;
    if (properties.find("SshSessionInfo") != properties.end()) {
        sshSessionInfos = std::get<SshSessionInfoType>(properties["SshSessionInfo"]);
    }
    else{
        sshSessionInfos.clear();
    }
    compareSessionInfos(sshSessionInfos);
}

void monitorSshSessionInfo(sdbusplus::bus::bus& bus) {
    auto match = sdbusplus::bus::match::match(
        bus,
        "type='signal',interface='org.freedesktop.DBus.Properties',"
        "member='PropertiesChanged',path='/xyz/openbmc_project/SessionManager',"
        "arg0='xyz.openbmc_project.SessionManager.Ssh'",
        handleSshSessionInfoSignal
    );

    while (true) {
        bus.process_discard();
        bus.wait();
    }
}


void registerService(const std::string& serviceName) {
    std::cout << "Registering service: " << serviceName << std::endl;

    if (serviceSessions.find(serviceName) != serviceSessions.end()) {
        std::cout << "Service " << serviceName << " is already registered." << std::endl;
        return;
    }

    SessionInfo sessionInfo = getServiceSessionInfo(serviceName);
    sessionInfo.sessionType = 3;             
    sessionInfo.mountType = "ssh session";

    auto bus = sdbusplus::bus::new_default();
    try {

        auto method = bus.new_method_call(sessionMgrservice,
                                          sessionMgrobjpath,
                                          sessionMgrInterface,
                                          "SessionRegister");

        method.append(sessionInfo.sessionId, sessionInfo.ipAddress, sessionInfo.username,
                      sessionInfo.sessionType, sessionInfo.privilege, sessionInfo.userId, sessionInfo.mountType);


        sdbusplus::message::message response = bus.call(method);
        bool success;
        response.read(success);

        if (success) {

            auto method2 = bus.new_method_call(
                sessionMgrservice, sessionMgrobjpath,
                dbusPropertyInterface, "Get");

            method2.append(sessionMgrSSHInterface, "SshSessionInfo");

            sdbusplus::message::message response2 = bus.call(method2);

            std::variant<std::vector<std::tuple<uint8_t, std::string, std::string, uint8_t, uint8_t, uint8_t, std::string>>> result;
            response2.read(result);

            const auto& sessionData = std::get<std::vector<std::tuple<uint8_t, std::string, std::string, uint8_t, uint8_t, uint8_t, std::string>>>(result);

            if (!sessionData.empty()) {
                const auto& lastEntry = sessionData.back();
                sessionInfo.sessionId = std::get<0>(lastEntry);  // Update session ID from the last entry
            } else {
                std::cerr << "Error: No session data available to update sessionId for service " << serviceName << std::endl;
            }

            serviceSessions[serviceName] = sessionInfo;
            std::cout << "successfully register service " << serviceName << std::endl;
            return;
        } else {
            std::cout << "Service " << serviceName << " registration failed." << std::endl;
        }
    } catch (const std::exception& e) {
        std::cerr << "Error registering service " << serviceName << ": " << e.what() << std::endl;
    }

    return;    
}

void deregisterService(const std::string& serviceName) {

    SessionInfo sessionInfo = serviceSessions[serviceName];

    UnregisterReason reason = UnregisterReason::LOGOUT_SESSION; 
    auto bus = sdbusplus::bus::new_default();
    try {
        auto method = bus.new_method_call(sessionMgrservice,
                sessionMgrobjpath,
                sessionMgrInterface,
                "SessionUnregister");

        method.append(sessionInfo.sessionId, sessionInfo.sessionType, static_cast<int>(reason));
        
        sdbusplus::message::message response = bus.call(method);
        bool success;
        response.read(success);


        if (success) {
            std::cout << "Service " << serviceName << " deregistered successfully for reason: ";
            serviceSessions.erase(serviceName);
            switch (reason) {
                case UnregisterReason::LOGOUT_SESSION:
                    std::cout << "Logout session" << std::endl;
                    break;
                case UnregisterReason::LOGOUT_EXPIRY:
                    std::cout << "Logout expiry" << std::endl;
                    break;
                case UnregisterReason::TERMINATED_UNEXPECTEDLY:
                    std::cout << "Session terminated unexpectedly" << std::endl;
                    break;
            }
            return;
        }
    } catch (const std::exception& e) {
        std::cerr << "Error deregistering service " << serviceName << ": " << e.what() << std::endl;
    }
    return;

}

std::vector<std::string> getTriggersProperty(sdbusplus::bus::bus& bus) {
    std::vector<std::string> triggers;
    auto method = bus.new_method_call(systemdService,
                                      "/org/freedesktop/systemd1/unit/dropbear_2esocket",
                                      dbusPropertyInterface,
                                      "Get");
    method.append("org.freedesktop.systemd1.Unit", "Triggers");

    try {
        sdbusplus::message::message reply = bus.call(method);
        
        std::variant<std::vector<std::string>> result;
        
        reply.read(result);
        
        triggers = std::get<std::vector<std::string>>(result);
        
    } catch (const std::exception& e) {
        std::cerr << "Failed to retrieve Triggers property: " << e.what() << std::endl;
    }
    return triggers;
}


void monitorTriggers() {
    auto bus = sdbusplus::bus::new_default();
    std::vector<std::string> variable1 = getTriggersProperty(bus);
    std::vector<std::string> variable2;

    for (const auto& service : variable1) {
        registerService(service);
    }

    while (true) {
        variable2 = getTriggersProperty(bus);

        for (const auto& service : variable1) {
            if (std::find(variable2.begin(), variable2.end(), service) == variable2.end()) {
                deregisterService(service);
                std::cout << "Deregistered service: " << service << std::endl;
            }
        }

        for (const auto& service : variable2) {
            if (std::find(variable1.begin(), variable1.end(), service) == variable1.end()) {
                registerService(service);
                std::cout << "Registered service: " << service << std::endl;
            }
        }

        variable1 = variable2;
        std::this_thread::sleep_for(std::chrono::seconds(monitorTriggersDelay));
    }
}


int main() {
    auto bus = sdbusplus::bus::new_default();

    sessionInfoList = getDbusProperty(bus);

    std::thread monitorThread(monitorTriggers);
    std::thread monitorThread1(monitorSshSessionInfo, std::ref(bus));

    monitorThread.join(); 
    monitorThread1.join();

    return 0;
}
