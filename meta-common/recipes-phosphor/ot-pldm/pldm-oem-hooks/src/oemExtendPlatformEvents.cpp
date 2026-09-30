#include <ot-pldm/libpldmresponder/types.hpp>
#include <phosphor-logging/lg2.hpp>
using namespace pldm::responder::platform;

#define PLDM_OEM_EVENT_CLASS_0xFE 0xFE

extern "C"
{
/** @brief Extend platform event handlers for PlatformEventMessage command
 *
 *  @param[out] eventMap - event class to event handlers map to be extended
 *  @warning eventMap is only used to extend platform event handlers, DO NOT
 * modify or clear existing event handlers in eventMap.
 *  @return 0 on success, non-zero on failure
 */
int oemExtendPlatformEvents(pldm::responder::platform::EventMap& eventMap)
{
    // lg2::info(
    //     "[pldm-oem-hooks : oemExtendPlatformEvents]
    //     PLDM_OEM_EVENT_CLASS_0xFE={CMD}", "CMD", PLDM_OEM_EVENT_CLASS_0xFE);

    eventMap[PLDM_OEM_EVENT_CLASS_0xFE].emplace_back(
        [](const pldm_msg* request, size_t payloadLength, uint8_t formatVersion,
           uint8_t tid, size_t eventDataOffset, uint8_t& platformEventStatus) {
            // lg2::info(
            //     "[pldm-oem-hooks : PLDM_OEM_EVENT_CLASS_0xFE] payloadLength:
            //     {PL}, formatVersion: {FV}, tid: {TID}, eventDataOffset:
            //     {EDO}, platformEventStatus: {PES}", "PL", payloadLength,
            //     "FV", formatVersion, "TID", tid, "EDO", eventDataOffset,
            //     "PES", platformEventStatus);
            return 0;
        });

    return 0;
}
}
