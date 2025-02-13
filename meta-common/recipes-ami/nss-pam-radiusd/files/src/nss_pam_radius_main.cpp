extern "C" {
#include "pam_helper.h"
}

#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <vector>
#include <algorithm>
#include <string>

#include <boost/asio/io_context.hpp>
#include <boost/asio/io_service.hpp>
#include <boost/asio/steady_timer.hpp>
#include <boost/container/flat_map.hpp>
#include <fstream>
#include <iostream>
#include <sdbusplus/asio/object_server.hpp>
#include <sdbusplus/message.hpp>

#define TRUE 1
#define FALSE 0
#define NUM_OF_PAM_USERS 16
#define RADIUSCLIENTCONF "/etc/radiusclient-ng/radiusclient.conf"
#define RADIUSSERVERCONF "/etc/radiusclient-ng/servers"

static constexpr const char *radiusService =
    "xyz.openbmc_project.Radius.Config";
static constexpr const char *radiusObj =
    "/xyz/openbmc_project/user/Radius/Config";
static constexpr const char *radiusIntf =
    "xyz.openbmc_project.User.Radius.Config";

static constexpr const char *radiusRoleObj =
    "/xyz/openbmc_project/user/Radius/role_map";
static constexpr const char *radiusRoleIntf =
    "xyz.openbmc_project.User.Radius.role_map";
constexpr const char* priv_admin = "priv-admin";
constexpr const char* priv_operator = "priv-operator";
constexpr const char* priv_user = "priv-user";
static const std::vector<std::string> privilege_list = {priv_admin, priv_operator, priv_user};

std::vector<std::string> vec = {"authserver", "acctserver"};
bool readWrite = 0;

pamusr_t pamusrtbl[NUM_OF_TBLTYPES][NUM_OF_PAM_USERS] = {};

tblinfo_t tblinfo[NUM_OF_TBLTYPES] = {
    {0, LDAP_FIRST_UID, LDAP_FIRST_UID, LDAP_LAST_UID},
    {0, AD_FIRST_UID, AD_FIRST_UID, AD_LAST_UID},
    {0, RADIUS_FIRST_UID, RADIUS_FIRST_UID, RADIUS_LAST_UID}};

static constexpr const char *userService = "xyz.openbmc_project.User.Manager";
static constexpr const char *userAttriIntf =
    "xyz.openbmc_project.User.Attributes";
void updateConfFile(std::string confFile, std::vector<std::string> matchString,
                    std::string replaceString, bool readWrite) {
  std::string confFileTmp = confFile + "tmp";
  std::ifstream file(confFile);
  std::string lineBuf;
  std::string tempBuf;
  std::string spaceBuf = {"    "};
  std::string readConf;

  if (!file.is_open()) {
    std::cerr << "Failed to open file" << confFile << std::endl;
    return;
  }

  std::ofstream outFile(confFileTmp);
  if (!outFile.is_open()) {
    std::cerr << "Failed to open file" << confFileTmp << std::endl;
    file.close();
    return;
  }

  for (const auto &str : matchString) {
    std::cerr << "Debug: matchString value: " << str << std::endl;
  }
  size_t i = 0;
  while (std::getline(file, lineBuf)) {
    if ((i < matchString.size()) &&
        (strstr(lineBuf.c_str(), matchString[i].c_str()) != nullptr)) {
      if (readWrite == 1) {
        sscanf(lineBuf.c_str(), "%s%s", tempBuf.c_str(), readConf.c_str());
        std::cerr << readConf << std::endl;
        replaceString = readConf.c_str();
        break;
      }
      /*matchString += "  " + replaceString*/
      tempBuf = matchString[i] + spaceBuf + replaceString;
      outFile << tempBuf << std::endl;
      i++;

    } else {
      outFile << lineBuf << std::endl;
    }
  }

  file.close();
  outFile.close();
  if (readWrite == 1) {
    if (std::remove(confFileTmp.c_str()) != 0) {
      std::cerr << "Error deleting file: " << confFileTmp << std::endl;
      return;
    } // remove temp file ;
  } else {
    if (std::rename(confFileTmp.c_str(), confFile.c_str()) != 0) {
      std::cerr << "Error renaming temporary file.\n";
      return;
    }
  }
  return;
}

void updateServerFile(const std::string &filename, int IpOrPassword,
                      const std::string &src) {

  std::string lastLine;
  int LineNumber = 0;
  std::string currentLine;
  std::string Buffer;

  std::ifstream infile(filename);
  if (!infile) {
    std::cerr << "Error opening file!" << std::endl;
    return;
  }

  std::ofstream outfile("/etc/radiusclient-ng/servers.txt");
  if (!outfile) {
    std::cerr << "Error opening file for writing!" << std::endl;
    return;
  }
  while (std::getline(infile, currentLine)) {
    LineNumber++;
    if (LineNumber == 5) {
      Buffer = currentLine;
      break;
    } else {
      outfile << currentLine << std::endl;
    }
  }

  if (Buffer.empty()) {
    Buffer = "servername\t\tsecretcode";
  }

  char *token = strtok((char *)Buffer.c_str(), "\t\t");
  if (IpOrPassword == 0) {
    outfile << token << "\t\t" << src;
  } else {
    token = strtok(NULL, "\t\t");
    outfile << src << "\t\t" << token;
  }

  infile.close();
  outfile.close();
  if (std::rename("/etc/radiusclient-ng/servers.txt",
                  "/etc/radiusclient-ng/servers") != 0) {
    std::cerr << "Error renaming temporary file.\n";
    return;
  }

  return;
}

int radiusPAMHandler() {
  pamusrpkt_t req, res;
  int i = 0, j = 0;
  int handle = 0, ret = 0;

  PAMH_CREATE_Q(PAM_HELPER_Q);
  PAMH_OPEN_Q(PAM_HELPER_Q, handle);
  if (handle < 0) {
    printf("--------- %s : error openig queue %s \n", __FILE__, PAM_HELPER_Q);
    return -1;
  }
  while (1) {
    memset(&req, 0, sizeof(pamusrpkt_t));
    if (0 != get_pam_userinfo(&req, PAM_HELPER_Q, handle, WAIT_INFINITE_TIME)) {
      printf(" %s : error fetching messages from queue %s \n", __FILE__,
             PAM_HELPER_Q);
      continue;
    }
    memset(&res, 0, sizeof(pamusrpkt_t));
    res.action = PAM_RESPONSE;

    if (req.pt >= NUM_OF_TBLTYPES) {
      res.ret = INVALID_TBL_TYPE;
      post_pam_userinfo(&res, req.srcq);
      continue;
    }

    res.pt = req.pt;

    switch (req.action) {
    case ADD_PAM_USER: {
      int i, j, user_found = 0, index = 0;
      pamusr_t *pusr_head, *pusr_next = &pamusrtbl[req.pt][0];
      index = (tblinfo[req.pt].index == 0) ? (NUM_OF_PAM_USERS - 1)
                                           : (tblinfo[req.pt].index - 1);
      for (i = 0, j = index; i < NUM_OF_PAM_USERS; i++) {
        pusr_head = (pusr_next + j);
        if (strncmp(pusr_head->name, req.usr.name,
                    strlen(pusr_head->name) + 1) == 0) {
          printf("%s :User already present in the queue\n", __FILE__);
          memcpy((char *)&res.usr, (char *)&pusr_head, sizeof(pamusr_t));
          user_found = 1;
          break;
        }
        j = (j == NUM_OF_PAM_USERS - 1) ? 0 : j + 1;
      }
      if (user_found == 0) {
        pamusr_t *u = &pamusrtbl[req.pt][tblinfo[req.pt].index];
        printf("Add Index: %d\n", tblinfo[req.pt].index);
        ret = snprintf(u->name, sizeof(u->name), "%s", req.usr.name);
        if (ret < 0 || ret >= (signed)sizeof(u->name)) {
          printf("Buffer Overflow\n");
          return -1;
        }
        u->priv = req.usr.priv;
        u->uid = tblinfo[req.pt].uid++;
        tblinfo[req.pt].index++;

        printf("Add Name : %s\n", u->name);
        printf("Add UID  : %d\n", u->uid);

        if ((tblinfo[req.pt].uid - 1) == tblinfo[req.pt].last_uid) {
          tblinfo[req.pt].uid = tblinfo[req.pt].first_uid;
          printf("UID: Change to %d\n", tblinfo[req.pt].uid);
        }
        if (tblinfo[req.pt].index == NUM_OF_PAM_USERS) {
          tblinfo[req.pt].index = 0;
          printf("Index: Change to 0\n");
        }
      }
      res.ret = PAM_USER_ADDED_SUCCESSFULLY;
      post_pam_userinfo(&res, req.srcq);
      /* This function is used to call whenever user added in any table.*
       * * when adding user, check whether any other database has the same
       * name..
       * * if then delete that user...*/
      remove_pam_user(req.usr.name, req.pt);
    } break;
    case GET_USERINFO_BY_NAME: {
      int indexloop = 0;
      pamusr_t *u, *ut = &pamusrtbl[req.pt][0];

      res.ret = PAM_USER_NOT_FOUND;

      indexloop = (tblinfo[req.pt].index == 0) ? (NUM_OF_PAM_USERS - 1)
                                               : (tblinfo[req.pt].index - 1);

      printf("Index lopp: %d\n", indexloop);
      for (i = 0, j = indexloop; i < NUM_OF_PAM_USERS; i++) {
        u = (ut + j);
        if (strncmp(u->name, req.usr.name, strlen(u->name) + 1) == 0) {
          printf("Search Found: %d\n", j);
          memcpy((char *)&res.usr, (char *)u, sizeof(pamusr_t));
          res.ret = PAM_USER_RETRIEVED_SUCCESSFULLY;
          break;
        }
        j = (j == (NUM_OF_PAM_USERS - 1)) ? 0 : (j + 1);
      }
      printf("Search Not Found: %d\n", j);
      post_pam_userinfo(&res, req.srcq);
    } break;
    case GET_USERINFO_BY_UID: {
      int indexloop = 0;
      pamusr_t *u, *ut = &pamusrtbl[req.pt][0];

      res.ret = PAM_USER_NOT_FOUND;

      indexloop = (tblinfo[req.pt].index == 0) ? (NUM_OF_PAM_USERS - 1)
                                               : (tblinfo[req.pt].index - 1);

      for (i = 0, j = indexloop; i < NUM_OF_PAM_USERS; i++) {
        u = (ut + j);
        if (u->uid == req.usr.uid) {
          printf("UID Search Found: %d\n", j);
          memcpy((char *)&res.usr, (char *)u, sizeof(pamusr_t));
          res.ret = PAM_USER_RETRIEVED_SUCCESSFULLY;
          break;
        }
        j = (j == (NUM_OF_PAM_USERS - 1)) ? 0 : (j + 1);
      }
      printf("UID Search Not Found: %d\n", j);
      post_pam_userinfo(&res, req.srcq);
    } break;
    case DEL_PAM_USER: {
      int indexloop = 0;
      pamusr_t *u, *ut = &pamusrtbl[req.pt][0];

      res.ret = PAM_USER_NOT_FOUND;

      indexloop = (tblinfo[req.pt].index == 0) ? (NUM_OF_PAM_USERS - 1)
                                               : (tblinfo[req.pt].index - 1);

      printf("Index lopp: %d\n", indexloop);
      for (i = 0, j = indexloop; i < NUM_OF_PAM_USERS; i++) {
        u = (ut + j);
        if (strncmp(u->name, req.usr.name, strlen(u->name) + 1) == 0) {
          printf("Search Found: %d\n", j);
          memset((char *)u, 0, sizeof(pamusr_t));
          res.ret = PAM_USER_DELETED_SUCCESSFULLY;
        }
        j = (j == (NUM_OF_PAM_USERS - 1)) ? 0 : (j + 1);
      }
      printf("Search Not Found: %d\n", j);
      post_pam_userinfo(&res, req.srcq);
    } break;
    default: {
      res.ret = INVALID_ACTION_REQUEST;
      post_pam_userinfo(&res, req.srcq);
    } break;
    }
  }
}

bool isPortInUse(int port) {
  if (port >= 0 && port <= 65535) {

    int sock = socket(AF_INET, SOCK_STREAM, 0);
    if (sock < 0) {
      return false;
    }

    struct sockaddr_in addr;
    addr.sin_family = AF_INET;
    addr.sin_addr.s_addr = INADDR_ANY;
    addr.sin_port = htons(port);

    int result = bind(sock, (struct sockaddr *)&addr, sizeof(addr));
    close(sock);

    if (result < 0) {
      return false;
    } else {
      return true;
    }
  } else {
    return false;
  }
}

int main() {
  pid_t pid = fork();
  if (pid == 0) {
    boost::asio::io_service io;
    auto conn = std::make_shared<sdbusplus::asio::connection>(io);
    conn->request_name(radiusService);
    auto server = sdbusplus::asio::object_server(conn);
    std::shared_ptr<sdbusplus::asio::dbus_interface> radIface =
        server.add_interface(radiusObj, radiusIntf);

    std::shared_ptr<sdbusplus::asio::dbus_interface> radRoleIface =
        server.add_interface(radiusRoleObj, radiusRoleIntf);

    std::string tmp = "";
    bool tmp_en = false;
    int tmp_i = 0;
    std::string oldstring;
    std::string newstring;

    radRoleIface->register_property(
        "GroupName1", tmp,
        [&tmp, &oldstring, &newstring](const std::string &requested,
                                       std::string &resp) {
          resp = requested;
          return 1;
        });
    radRoleIface->register_property(
        "Privilege1", tmp,
        [&tmp, &oldstring, &newstring](const std::string &requested,
                                       std::string &resp) {
          if (std::find(privilege_list.begin(), privilege_list.end(), requested) != privilege_list.end()) {
	  resp = requested;
          return 1;
	  }
	  else {
	  return 0;
	  }
        });

    radRoleIface->register_property(
        "GroupName2", tmp,
        [&tmp, &oldstring, &newstring](const std::string &requested,
                                       std::string &resp) {
          resp = requested;
          return 1;
        });
    radRoleIface->register_property(
        "Privilege2", tmp,
        [&tmp, &oldstring, &newstring](const std::string &requested,
                                       std::string &resp) {
          if (std::find(privilege_list.begin(), privilege_list.end(), requested) != privilege_list.end()) {
	  resp = requested;
          return 1;
	  }
	  else {
	  return 0;
	  }
        });

    radRoleIface->register_property(
        "GroupName3", tmp,
        [&tmp, &oldstring, &newstring](const std::string &requested,
                                       std::string &resp) {
          resp = requested;
          return 1;
        });
    radRoleIface->register_property(
        "Privilege3", tmp,
        [&tmp, &oldstring, &newstring](const std::string &requested,
                                       std::string &resp) {
          if (std::find(privilege_list.begin(), privilege_list.end(), requested) != privilege_list.end()) {
	  resp = requested;
          return 1;
	  }
	  else {
	  return 0;
	  }
        });

    radIface->register_property(
        "IP", tmp,
        [&tmp, &oldstring, &newstring](const std::string &requested,
                                       std::string &resp) {
          updateConfFile(RADIUSCLIENTCONF, vec, requested, 0);
          newstring = requested;
          updateServerFile(RADIUSSERVERCONF, 1, newstring);
          resp = requested;
          return 1;
        });
    radIface->register_property(
        "Password", tmp,
        [&tmp, &oldstring, &newstring](const std::string &requested,
                                       std::string &resp) {
          newstring = requested;
          updateServerFile(RADIUSSERVERCONF, 0, newstring);
          resp = requested;
          return 1;
        });
    radIface->register_property("Enable", tmp_en,
                                [](const bool &requested, bool &resp) {
                                  resp = requested;
                                  return 1;
                                });

    radIface->register_property("PortNumber", tmp_i,
                                [](const int &requested, int &resp) {
                                  if (isPortInUse(requested) == true) {
                                    resp = requested;
                                    return 1;
                                  } else {
                                    resp = -1;
                                    return 0;
                                  }
                                });

    radIface->register_method(
        "Send",
        [&](const std::string &subject, const std::string &msg) { return 0; });

    radIface->initialize();
    radRoleIface->initialize();
    io.run();
  } else {
    pamusrpkt_t req, res;
    int i = 0, j = 0;
    int handle = 0, ret = 0;

    PAMH_CREATE_Q(PAM_HELPER_Q);
    PAMH_OPEN_Q(PAM_HELPER_Q, handle);
    if (handle < 0) {
      printf("--------- %s : error openig queue %s \n", __FILE__, PAM_HELPER_Q);
      return -1;
    }
    while (1) {
      memset(&req, 0, sizeof(pamusrpkt_t));
      if (0 !=
          get_pam_userinfo(&req, PAM_HELPER_Q, handle, WAIT_INFINITE_TIME)) {
        printf(" %s : error fetching messages from queue %s \n", __FILE__,
               PAM_HELPER_Q);
        continue;
      }
      memset(&res, 0, sizeof(pamusrpkt_t));
      res.action = PAM_RESPONSE;

      if (req.pt >= NUM_OF_TBLTYPES) {
        res.ret = INVALID_TBL_TYPE;
        post_pam_userinfo(&res, req.srcq);
        continue;
      }

      res.pt = req.pt;

      switch (req.action) {
      case ADD_PAM_USER: {
        int i, j, user_found = 0, index = 0;
        pamusr_t *pusr_head, *pusr_next = &pamusrtbl[req.pt][0];
        index = (tblinfo[req.pt].index == 0) ? (NUM_OF_PAM_USERS - 1)
                                             : (tblinfo[req.pt].index - 1);
        for (i = 0, j = index; i < NUM_OF_PAM_USERS; i++) {
          pusr_head = (pusr_next + j);
          if (strncmp(pusr_head->name, req.usr.name,
                      strlen(pusr_head->name) + 1) == 0) {
            printf("%s :User already present in the queue\n", __FILE__);
            memcpy((char *)&res.usr, (char *)&pusr_head, sizeof(pamusr_t));
            user_found = 1;
            break;
          }
          j = (j == NUM_OF_PAM_USERS - 1) ? 0 : j + 1;
        }
        if (user_found == 0) {
          pamusr_t *u = &pamusrtbl[req.pt][tblinfo[req.pt].index];
          printf("Add Index: %d\n", tblinfo[req.pt].index);
          ret = snprintf(u->name, sizeof(u->name), "%s", req.usr.name);
          if (ret < 0 || ret >= (signed)sizeof(u->name)) {
            printf("Buffer Overflow\n");
            return -1;
          }
          u->priv = req.usr.priv;
          u->uid = tblinfo[req.pt].uid++;
          tblinfo[req.pt].index++;

          if ((tblinfo[req.pt].uid - 1) == tblinfo[req.pt].last_uid) {
            tblinfo[req.pt].uid = tblinfo[req.pt].first_uid;
          }
          if (tblinfo[req.pt].index == NUM_OF_PAM_USERS) {
            tblinfo[req.pt].index = 0;
          }
        }
        res.ret = PAM_USER_ADDED_SUCCESSFULLY;
        post_pam_userinfo(&res, req.srcq);
        /* This function is used to call whenever user added in any table.*
         * * when adding user, check whether any other database has the same
         * name..
         * * if then delete that user...*/
        remove_pam_user(req.usr.name, req.pt);
      } break;
      case GET_USERINFO_BY_NAME: {
        int indexloop = 0;
        pamusr_t *u, *ut = &pamusrtbl[req.pt][0];

        res.ret = PAM_USER_NOT_FOUND;

        indexloop = (tblinfo[req.pt].index == 0) ? (NUM_OF_PAM_USERS - 1)
                                                 : (tblinfo[req.pt].index - 1);

        for (i = 0, j = indexloop; i < NUM_OF_PAM_USERS; i++) {
          u = (ut + j);
          if (strncmp(u->name, req.usr.name, strlen(u->name) + 1) == 0) {
            memcpy((char *)&res.usr, (char *)u, sizeof(pamusr_t));
            res.ret = PAM_USER_RETRIEVED_SUCCESSFULLY;
            break;
          }
          j = (j == (NUM_OF_PAM_USERS - 1)) ? 0 : (j + 1);
        }
        post_pam_userinfo(&res, req.srcq);
      } break;
      case GET_USERINFO_BY_UID: {
        int indexloop = 0;
        pamusr_t *u, *ut = &pamusrtbl[req.pt][0];

        res.ret = PAM_USER_NOT_FOUND;

        indexloop = (tblinfo[req.pt].index == 0) ? (NUM_OF_PAM_USERS - 1)
                                                 : (tblinfo[req.pt].index - 1);

        for (i = 0, j = indexloop; i < NUM_OF_PAM_USERS; i++) {
          u = (ut + j);
          if (u->uid == req.usr.uid) {
            memcpy((char *)&res.usr, (char *)u, sizeof(pamusr_t));
            res.ret = PAM_USER_RETRIEVED_SUCCESSFULLY;
            break;
          }
          j = (j == (NUM_OF_PAM_USERS - 1)) ? 0 : (j + 1);
        }
        post_pam_userinfo(&res, req.srcq);
      } break;
      case DEL_PAM_USER: {
        int indexloop = 0;
        pamusr_t *u, *ut = &pamusrtbl[req.pt][0];

        res.ret = PAM_USER_NOT_FOUND;

        indexloop = (tblinfo[req.pt].index == 0) ? (NUM_OF_PAM_USERS - 1)
                                                 : (tblinfo[req.pt].index - 1);

        for (i = 0, j = indexloop; i < NUM_OF_PAM_USERS; i++) {
          u = (ut + j);
          if (strncmp(u->name, req.usr.name, strlen(u->name) + 1) == 0) {
            memset((char *)u, 0, sizeof(pamusr_t));
            res.ret = PAM_USER_DELETED_SUCCESSFULLY;
          }
          j = (j == (NUM_OF_PAM_USERS - 1)) ? 0 : (j + 1);
        }
        post_pam_userinfo(&res, req.srcq);
      } break;
      default: {
        res.ret = INVALID_ACTION_REQUEST;
        post_pam_userinfo(&res, req.srcq);
      } break;
      }
    }
  }
  return 0;
}
