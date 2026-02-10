#pragma once
#include "syslog.h"

#include "redfish-core/lib/redfish_util.hpp"
#include "redfish-core/lib/storage.hpp"
#include "registries/privilege_registry.hpp"
#if (BMCWEB_AMI_REP_MACRO)
#include "ext/lib/rep/storage_header.hpp" //Added this header file to call the BiosStorageInstance from the existing route using REP macro
#endif

#if (BMCWEB_AMI_REP_MACRO) || (BMCWEB_AMI_NVME_MACRO) || (BMCWEB_AMI_RAIDMSCC_MACRO) ||                  \
    (BMCWEB_AMI_RAIDBRCM_MACRO) || (BMCWEB_AMI_SL8_MACRO)
#include "ext/include/collection_ext.hpp"
#endif

namespace redfish::ext::core::resource
{

inline void handleSystemsStorageCollectionGet(
    App& app, const crow::Request& req,
    const std::shared_ptr<bmcweb::AsyncResp>& asyncResp,
    const std::string& systemName)
{
    if (!redfish::setUpRedfishRoute(app, req, asyncResp))
    {
        return;
    }
    if (systemName != BMCWEB_REDFISH_SYSTEM_URI_NAME)
    {
        messages::resourceNotFound(asyncResp->res, "ComputerSystem",
                                   systemName);
        return;
    }

    asyncResp->res.jsonValue["@odata.type"] =
        "#StorageCollection.StorageCollection";
    asyncResp->res.jsonValue["@odata.id"] = std::format(
        "/redfish/v1/Systems/{}/Storage", BMCWEB_REDFISH_SYSTEM_URI_NAME);
    asyncResp->res.jsonValue["Name"] = "Storage Collection";
    asyncResp->res.jsonValue["Description"] =
        "Collection of storage for this system";

    constexpr std::array<std::string_view, 1> interface{
        "xyz.openbmc_project.Inventory.Item.Storage"};
    collection::getCollectionMembers(
        asyncResp,
        boost::urls::format("/redfish/v1/Systems/{}/Storage",
                            BMCWEB_REDFISH_SYSTEM_URI_NAME),
        interface, "/xyz/openbmc_project/inventory",
        true); // added "true" paramater for ami storage devices);
}

inline void requestStorageCollectionRoutes(App& app)
{
    BMCWEB_ROUTE(app, "/redfish/v1/Systems/<str>/Storage/")
        .privileges(redfish::privileges::getStorageCollection)
        .methods(boost::beast::http::verb::get)(
            std::bind_front(handleSystemsStorageCollectionGet, std::ref(app)));
}

inline void afterSystemsStorageGetSubtree(
    const std::shared_ptr<bmcweb::AsyncResp>& asyncResp,
    const std::string& storageId, const boost::system::error_code& ec,
    const dbus::utility::MapperGetSubTreeResponse& subtree)
{
    if (ec)
    {
        BMCWEB_LOG_DEBUG("requestRoutesStorage DBUS response error");
        messages::resourceNotFound(asyncResp->res, "#Storage.v1_13_0.Storage",
                                   storageId);
        return;
    }
    auto storage = std::ranges::find_if(
        subtree,
        [&storageId](const std::pair<std::string,
                                     dbus::utility::MapperServiceMap>& object) {
            return sdbusplus::message::object_path(object.first).filename() ==
                   storageId;
        });
    if (storage == subtree.end())
    {
#if BMCWEB_AMI_RAIDBRCM_MACRO
        {
            std::size_t raid = storageId.find("Raid_");
            std::size_t hba = storageId.find("HBA_");
            if ((raid != std::string::npos) || (hba != std::string::npos))
            {
                return;
            }
        }
#endif
#if BMCWEB_AMI_SL8_MACRO
        {
            std::size_t sl8 = storageId.find("Raidsl8_");
            if (sl8 != std::string::npos)
            {
                return;
            }
        }
#endif
#if BMCWEB_AMI_RAIDMSCC_MACRO
        {
            std::size_t mscc = storageId.find("mscc_");
            if ((mscc != std::string::npos))
            {
                return;
            }
        }
#endif
#if BMCWEB_AMI_NVME_MACRO
        {
            if ((storageId == "Nvme"))
            {
                return;
            }
        }
#endif
        messages::resourceNotFound(asyncResp->res, "#Storage.v1_13_0.Storage",
                                   storageId);
        return;
    }
    asyncResp->res.jsonValue["@odata.type"] = "#Storage.v1_13_0.Storage";
    asyncResp->res.jsonValue["@odata.id"] =
        boost::urls::format("/redfish/v1/Systems/{}/Storage/{}",
                            BMCWEB_REDFISH_SYSTEM_URI_NAME, storageId);
    asyncResp->res.jsonValue["Name"] = "Storage";
    asyncResp->res.jsonValue["Id"] = storageId;
    asyncResp->res.jsonValue["Status"]["State"] = "Enabled";

    redfish::getDrives(asyncResp);
    asyncResp->res.jsonValue["Controllers"]["@odata.id"] =
        boost::urls::format("/redfish/v1/Systems/{}/Storage/{}/Controllers",
                            BMCWEB_REDFISH_SYSTEM_URI_NAME, storageId);
}

inline void handleSystemsStorageGet(
    App& app, const crow::Request& req,
    const std::shared_ptr<bmcweb::AsyncResp>& asyncResp,
    const std::string& systemName, const std::string& storageId)
{
    asyncResp->res.clearHeader(boost::beast::http::field::allow);
    asyncResp->res.jsonValue["Description"] = "Storage " + storageId;
    if (!redfish::setUpRedfishRoute(app, req, asyncResp))
    {
        return;
    }
    if constexpr (BMCWEB_EXPERIMENTAL_REDFISH_MULTI_COMPUTER_SYSTEM)
    {
        // Option currently returns no systems.  TBD
        messages::resourceNotFound(asyncResp->res, "ComputerSystem",
                                   systemName);
        return;
    }
    if (!membersResponseGet(asyncResp, storageId, "StorageCollection"))
    {
        return;
    }
    asyncResp->res.addHeader("Allow", "GET");
#if BMCWEB_AMI_RAIDBRCM_MACRO
    {
        std::size_t raid = storageId.find("Raid_");
        std::size_t hba = storageId.find("HBA_");

        if ((raid != std::string::npos) || (hba != std::string::npos))
        {
            redfish::getBRCMStorageInstance(asyncResp, storageId);
        }
    }
#endif
#if BMCWEB_AMI_SL8_MACRO
    {
        std::size_t sl8 = storageId.find("Raidsl8_");
        if (sl8 != std::string::npos)
        {
            redfish::getSl8StorageInstance(asyncResp, storageId);
        }
    }
#endif
#if BMCWEB_AMI_RAIDMSCC_MACRO
    {
        std::size_t mscc = storageId.find("mscc_");
        if ((mscc != std::string::npos))
        {
            constexpr std::array<std::string_view, 1> interfaces = {
                "com.ami.storage.mscc.ctrl.Controller"};
            dbus::utility::getSubTree(
                "/com/ami/storage/mscc", 0, interfaces,
                std::bind_front(redfish::getMSCCStorageInstance, asyncResp,
                                storageId));
        }
    }
#endif
#if BMCWEB_AMI_NVME_MACRO
    {
        if (storageId == "Nvme")
        {
            redfish::getStorageNvmeInstance(asyncResp);
        }
    }
#endif
#if BMCWEB_AMI_REP_MACRO
    {
        if (storageId.find("StorageUnit_") != std::string::npos)
        {
            redfish::handleStorageRep(asyncResp, storageId);
            return;
        }
    }
#endif
    constexpr std::array<std::string_view, 1> interfaces = {
        "xyz.openbmc_project.Inventory.Item.Storage"};
    dbus::utility::getSubTree(
        "/xyz/openbmc_project/inventory", 0, interfaces,
        std::bind_front(afterSystemsStorageGetSubtree, asyncResp, storageId));
}

inline void requestRoutesStorage(App& app)
{
    BMCWEB_ROUTE(app, "/redfish/v1/Systems/<str>/Storage/<str>/")
        .privileges(redfish::privileges::getStorage)
        .methods(boost::beast::http::verb::get)(
            std::bind_front(handleSystemsStorageGet, std::ref(app)));

    BMCWEB_ROUTE(app, "/redfish/v1/Systems/<str>/Storage/<str>/")
        .methods(boost::beast::http::verb::post,
                 boost::beast::http::verb::patch, boost::beast::http::verb::put,
                 boost::beast::http::verb::delete_)(
            [&app](const crow::Request& /* req */,
                   const std::shared_ptr<bmcweb::AsyncResp>& asyncResp,
                   const std::string& /* systemName */,
                   const std::string& storageId) {
                asyncResp->res.clearHeader(boost::beast::http::field::allow);       
                if (!membersResponseGet(asyncResp, storageId,
                                        "StorageCollection"))
                {
                    return;
                }
                asyncResp->res.addHeader("Allow", "GET");
                messages::operationNotAllowed(asyncResp->res);
            });
}

} // namespace redfish::ext::core::resource
