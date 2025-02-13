#pragma once

#include <boost/config.hpp>

namespace redfish::ami::extension
{

/*
 * @brief Top level class installing and providing AMI Redfish extension service
 */
template<typename App>
class BOOST_SYMBOL_VISIBLE Service
{
  public:
    /*
     * @brief Request routes for AMI Redfish extension service
     *
     * Loads Redfish configuration and installs schema resources
     *
     * @param[in] app Crow app on which Redfish will initialize
     */
    virtual void requestRoutes(App& app) const = 0;
};

} // namespace redfish::ami::extension
