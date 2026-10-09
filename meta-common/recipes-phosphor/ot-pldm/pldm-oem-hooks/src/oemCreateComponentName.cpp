#include <phosphor-logging/lg2.hpp>

#include <map>
#include <string>
#include <vector>

const std::map<std::string, std::string> customCompNameTable = {
    {"50b5c8aa-112c-ed11-8000-b83fd22dd85a", "CX75510AA"},
    {"88583dd9-1061-ef11-8000-c470bd7416a4", "CX755106A"},
    {"4cead29e-fb60-ef11-8000-c470bd7442f4", "MCX755106AS_HEAT"},
    {"5af04860-05df-11e4-af79-507c6f57007c", "E810XXVDA2"},
    {"5af04860-05df-11e4-af79-fcd78b9196b4", "E810XXVDA2"},
    {"ae0a96c0-cb06-11e5-a837-b8599f426e4a", "MCX4121A"},
    {"ae0a96c0-cb06-11e5-a837-b8599f426ece", "MCX4121A"},
    {"5af04860-05df-11e4-af79-507c6f4574f8", "E810XXVDA4"},
    {"e4fc4c3e-70f7-e811-8000-98039b8c55b4", "MCX512F"},
    {"9d4ebb85-4542-5a5f-8389-960e47888eba", "9600_16i"},
    {"7d0fad9a-234c-56c0-8e46-f62081a84f00", "9660_16i"},
    {"e01ac16e-75c5-5a90-8bf8-8dd57cc4d887", "AC113013005R9660_16i"},
    {"c54d7b7b-1242-5332-87ac-f939ea3fedc5", "AC1140112149670_24i"},
    {"9954cb95-8784-5000-9b63-76045bc3f125", "AC11209660_16i"},
};

using namespace std;
extern "C"
{
/** @brief Create component name for firmware update and logging service
 *
 *  @param[in] eid - MCTP EID
 *  @param[in] uuid - Device UUID
 *  @param[in] compId - ComponentIdentifier mentioned in PLDM DSP0267
 *  @param[out] compName - Customized component name to be created
 *  @return 0 on success, non-zero on failure
 */
int oemCreateComponentName(uint8_t eid, string uuid, uint16_t compId,
                           string& compName)
{
    if (customCompNameTable.find(uuid) != customCompNameTable.end())
    {
        compName += "PLDM_" + customCompNameTable.at(uuid);
    }
    else
    {
        compName = "PLDM_Firmware";
    }

    // lg2::info(
    //     "[pldm-oem-hooks : oemCreateComponentName]
    //     ComponentName({COMPNAME})", "COMPNAME", compName);
    return 0;
}
}
