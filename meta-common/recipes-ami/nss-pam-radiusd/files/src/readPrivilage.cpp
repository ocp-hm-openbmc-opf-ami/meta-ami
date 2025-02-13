#include <iostream>
#include <readPrivilage.h>
#include <sdbusplus/asio/object_server.hpp>
#include <syslog.h>

using DbusUserPropVariant =
    std::variant<int, std::vector<std::string>, std::string, bool>;

extern "C" {
int getDbusProperty(char *groupName, char *priv) {

  std::string service = "xyz.openbmc_project.Radius.Config";
  std::string objPath = "/xyz/openbmc_project/user/Radius/role_map";
  std::string interface = "xyz.openbmc_project.User.Radius.role_map";
  std::string property;
  std::string privlage;
  std::string sGroupName;
  DbusUserPropVariant variant;
  std::string cToCpp(groupName);

  // Setting starting append name for radius property
  int i = 1;

  auto bus = sdbusplus::bus::new_default();
  for (i; i < 4; i++) {
    try {
      auto method =
          bus.new_method_call(service.c_str(), objPath.c_str(),
                              "org.freedesktop.DBus.Properties", "Get");
      property = "GroupName" + std::to_string(i);
      method.append(interface, property);

      auto reply = bus.call(method);
      reply.read(variant);
      sGroupName = std::get<std::string>(variant);
      if ((sGroupName.length()>2) && (std::strstr(cToCpp.c_str(), sGroupName.c_str()) != nullptr)) {
        auto method =
            bus.new_method_call(service.c_str(), objPath.c_str(),
                                "org.freedesktop.DBus.Properties", "Get");
        property.clear();
        property = "Privilege" + std::to_string(i);
        method.append(interface, property);

        auto reply = bus.call(method);
        reply.read(variant);
        privlage = std::get<std::string>(variant);
        memset(groupName,0,strlen(groupName));
        memcpy(groupName, sGroupName.c_str(), sGroupName.size() + 1);
        memcpy(priv, privlage.c_str(), privlage.size() + 1);
        return 0;
      }
      property.clear();

    } catch (const sdbusplus::exception_t &e) {
      std::cerr << "Fail to getDbusProperty" << std::endl;
        memset(groupName,0,strlen(groupName));
        return -1;
    }
    //syslog(LOG_WARNING,"server's response = %s privilage read = %s not fournd next search\n", p,privlage);
    syslog(LOG_WARNING,"server's responseprivilage read notfournd next sear");
    fprintf(stderr,"server's responseprivilage read notfournd next sear");
        memset(groupName,0,strlen(groupName));
  }
  return -1;
}

int getRadiusEnableDbusProperty(bool *radiusEnableStatus) {

  std::string service = "xyz.openbmc_project.Radius.Config";
  std::string objPath = "/xyz/openbmc_project/user/Radius/Config";
  std::string interface = "xyz.openbmc_project.User.Radius.Config";
  std::string property;
  std::string enableStatus;
  DbusUserPropVariant variant;

  auto bus = sdbusplus::bus::new_default();
  try {
    auto method = bus.new_method_call(service.c_str(), objPath.c_str(),
                                      "org.freedesktop.DBus.Properties", "Get");
    property = "Enable";
    method.append(interface, property);

    auto reply = bus.call(method);
    reply.read(variant);
    *radiusEnableStatus = std::get<bool>(variant);
    return 0;

  } catch (const sdbusplus::exception_t &e) {
    std::cerr << "Fail to getRadiusEnableProperty" << std::endl;
  }
  return -1;
}

int getRadiusPortDbusProperty(int *radiusPortNo) {

  std::string service = "xyz.openbmc_project.Radius.Config";
  std::string objPath = "/xyz/openbmc_project/user/Radius/Config";
  std::string interface = "xyz.openbmc_project.User.Radius.Config";
  std::string property;
  DbusUserPropVariant variant;

  auto bus = sdbusplus::bus::new_default();
  try {
    auto method = bus.new_method_call(service.c_str(), objPath.c_str(),
                                      "org.freedesktop.DBus.Properties", "Get");
    property = "PortNumber";
    method.append(interface, property);

    auto reply = bus.call(method);
    reply.read(variant);
    *radiusPortNo = std::get<int>(variant);
    return 0;

  } catch (const sdbusplus::exception_t &e) {
    std::cerr << "Fail to getRadiusPortProperty" << std::endl;
  }
  return -1;
}
}
