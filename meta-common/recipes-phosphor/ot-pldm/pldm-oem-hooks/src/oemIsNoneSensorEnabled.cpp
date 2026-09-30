
#include <phosphor-logging/lg2.hpp>

using namespace std;
extern "C"
{
/** @brief To skip the base unit as none type sensor
 *
 *  @return true to enable none type sensor, false to disable
 */
bool oemIsNoneSensorEnabled()
{
    return false;
}
}
