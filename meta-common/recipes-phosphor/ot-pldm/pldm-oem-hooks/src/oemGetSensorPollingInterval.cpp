#include <cstdint>

extern "C"
{
/** @brief OEM hook for sensor polling interval
 *
 *  @param[out] pollingInterval - sensor polling interval in microseconds
 *  @return 0 on success, non-zero on failure
 */
int oemGetSensorPollingInterval(std::uint64_t& pollingInterval)
{
    pollingInterval = 200000;
    return 0;
}
}
