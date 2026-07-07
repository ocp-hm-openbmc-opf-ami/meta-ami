#include <ot-pldm/libpldmresponder/types.hpp>
#include <ot-pldm/pldmd/handler.hpp>
#include <phosphor-logging/lg2.hpp>

#include <memory>

using namespace pldm::responder;

#define PLDM_OEM_TYPE_0x3E 0x3E
#define PLDM_OEM_CMD_0x00 0x00

/*
 * OemCmdHandler as an example of OEM command handler
 * handlers.emplace for your own command and handler function
 */
class OemCmdHandler : public CmdHandler
{
  public:
    OemCmdHandler()
    {
        handlers.emplace(PLDM_OEM_CMD_0x00, [this](pldm_tid_t,
                                                   const pldm_msg* request,
                                                   size_t payloadLength) {
            lg2::info(
                "[pldm-oem-hooks : PLDM_OEM_CMD_0x00] PLDM_OEM_TYPE_0x3E:{TYPE} PLDM_OEM_CMD_0x00:{CMD} payloadLength: {PL}",
                "TYPE", PLDM_OEM_TYPE_0x3E, "CMD", PLDM_OEM_CMD_0x00, "PL",
                payloadLength);
            return std::vector<uint8_t>{};
        });
    }
};

extern "C"
{
/** @brief Register customized PLDM type event handlers
 *
 *  @param[out] cmdHandlerMap - The map PLDM type to event handlers to be
 * registered
 *  @warning If there is already a handler for the same PLDM type in
 * cmdHandlerMap, the new one will not be replaced.
 *  @return 0 on success, non-zero on failure
 */
int oemRegisterCmdHandlers(CmdHandlerMap& cmdHandlerMap)
{
    lg2::info(
        "[pldm-oem-hooks : oemRegisterCmdHandlers] PLDM_OEM_TYPE_0x3E={TYPE} PLDM_OEM_CMD_0x00={CMD}",
        "TYPE", PLDM_OEM_TYPE_0x3E, "CMD", PLDM_OEM_CMD_0x00);
    auto result = cmdHandlerMap.emplace(PLDM_OEM_TYPE_0x3E,
                                        std::make_unique<OemCmdHandler>());
    if (!result.second)
    {
        lg2::info(
            "[pldm-oem-hooks : oemRegisterCmdHandlers] Skip registering OEM command handler, already exists for type: {TYPE}",
            "TYPE", PLDM_OEM_TYPE_0x3E);
    }
    return 0;
}
}
