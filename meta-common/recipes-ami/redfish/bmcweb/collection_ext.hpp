#pragma once

#include "bmcweb_config.h"

#include "async_resp.hpp"
#include "dbus_utility.hpp"
#include "error_messages.hpp"
#include "http/utility.hpp"
#include "human_sort.hpp"

#include <boost/url/url.hpp>
#include <nlohmann/json.hpp>

#include <ranges>
#include <span>
#include <string>
#include <string_view>
#include <vector>

namespace redfish::ext::core::collection
{

inline void handleCollectionMembers(
    const std::shared_ptr<bmcweb::AsyncResp>& asyncResp,
    const boost::urls::url& collectionPath,
    const nlohmann::json::json_pointer& jsonKeyName, bool check,
    const boost::system::error_code& ec,
    const dbus::utility::MapperGetSubTreePathsResponse& objects)
{
    if (jsonKeyName.empty())
    {
        messages::internalError(asyncResp->res);
        BMCWEB_LOG_ERROR("Json Key called empty.  Did you mean /Members?");
        return;
    }
    nlohmann::json::json_pointer jsonCountKeyName = jsonKeyName;
    std::string back = jsonCountKeyName.back();
    jsonCountKeyName.pop_back();
    jsonCountKeyName /= back + "@odata.count";

    if (ec == boost::system::errc::io_error)
    {
        asyncResp->res.jsonValue[jsonKeyName] = nlohmann::json::array();
        asyncResp->res.jsonValue[jsonCountKeyName] = 0;
        return;
    }

    if (ec)
    {
        BMCWEB_LOG_DEBUG("DBUS response error {}", ec.value());
        messages::internalError(asyncResp->res);
        return;
    }

    std::vector<std::string> pathNames;
    for (const auto& object : objects)
    {
        sdbusplus::message::object_path path(object);
        std::string leaf = path.filename();
        if (leaf.empty())
        {
            continue;
        }
        pathNames.push_back(leaf);
    }
    std::ranges::sort(pathNames, AlphanumLess<std::string>());

    nlohmann::json& members = asyncResp->res.jsonValue[jsonKeyName];
    members = nlohmann::json::array();
    for (const std::string& leaf : pathNames)
    {
        boost::urls::url url = collectionPath;
        crow::utility::appendUrlPieces(url, leaf);
        nlohmann::json::object_t member;
        member["@odata.id"] = std::move(url);
        members.emplace_back(std::move(member));
    }
    std::string additionalUrl;

    if (collectionPath.buffer() == "/redfish/v1/Systems/system/Storage")
    {
        additionalUrl = "/redfish/v1/Systems/system/Storage/1";
    }

    else if (collectionPath.buffer() == "/redfish/v1/Storage")
    {
        additionalUrl = "/redfish/v1/Storage/1";
    }

    if (!additionalUrl.empty())
    {
        nlohmann::json::object_t additionalMember;
        additionalMember["@odata.id"] = std::move(additionalUrl);
        members.emplace_back(std::move(additionalMember));
    }
    asyncResp->res.jsonValue[jsonCountKeyName] = members.size();
    if (check)
    {
        nlohmann::json& count = asyncResp->res.jsonValue[jsonCountKeyName];
        nlohmann::json& storageControllerArray = members;
#if BMCWEB_AMI_RAIDBRCM_MACRO
        {
            redfish::getRaidDevices(asyncResp, count, storageControllerArray);
            redfish::getHBADevices(asyncResp, count, storageControllerArray);
        }
#endif
#if BMCWEB_AMI_RAIDMSCC_MACRO
        redfish::getMSCCDevices(asyncResp, count, storageControllerArray);
#endif
#if BMCWEB_AMI_NVME_MACRO
        redfish::getNvmeDevices(asyncResp, count, storageControllerArray);
#endif
    }
}

/**
 * @brief Populate the collection members from a GetSubTreePaths search of
 *        inventory
 *
 * @param[i,o] asyncResp  Async response object
 * @param[i]   collectionPath  Redfish collection path which is used for the
 *             Members Redfish Path
 * @param[i]   interfaces  List of interfaces to constrain the GetSubTree search
 * @param[in]  subtree     D-Bus base path to constrain search to.
 * @param[in]  jsonKeyName Key name in which the collection members will be
 *             stored.
 *
 * @return void
 */
inline void getCollectionToKey(
    const std::shared_ptr<bmcweb::AsyncResp>& asyncResp,
    const boost::urls::url& collectionPath,
    std::span<const std::string_view> interfaces, const std::string& subtree,
    const nlohmann::json::json_pointer& jsonKeyName, bool check = false)
{
    BMCWEB_LOG_DEBUG("Get collection members for: {}", collectionPath.buffer());
    dbus::utility::getSubTreePaths(subtree, 0, interfaces,
                                   std::bind_front(handleCollectionMembers,
                                                   asyncResp, collectionPath,
                                                   jsonKeyName, check));
}
inline void
    getCollectionMembers(const std::shared_ptr<bmcweb::AsyncResp>& asyncResp,
                         const boost::urls::url& collectionPath,
                         std::span<const std::string_view> interfaces,
                         const std::string& subtree, bool check = false)
{
    getCollectionToKey(asyncResp, collectionPath, interfaces, subtree,
                       nlohmann::json::json_pointer("/Members"), check);
}

} // namespace redfish::ext::core::collection
