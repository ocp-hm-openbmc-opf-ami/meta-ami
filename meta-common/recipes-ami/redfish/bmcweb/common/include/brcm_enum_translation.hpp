#pragma once

#include "error_messages.hpp"
#include "http_response.hpp"

#include <algorithm>
#include <string>
#include <string_view>
#include <unordered_map>
#include <vector>

namespace redfish
{
namespace brcm_enum
{

// D-Bus enum namespace prefix used by the BRCM SL8 RAID backend
// (com.ami.storage.brcm8.Enumerations.<EnumType>.<Value>).
inline constexpr std::string_view sl8EnumNamespace =
    "com.ami.storage.brcm8.Enumerations.";

// Allowed plain values per enum type, from the SL8 User Guide Enumerations
// appendix. Enum types not listed here are not validated (fail-open).
inline const std::unordered_map<std::string_view, std::vector<std::string_view>>
    allowedEnumValues{
        {"PhysicalDriveState",
         {"Unknown", "Unconfigured", "RaidConfigured", "RaidHotSpare", "Host",
          "AdvHost", "Unusable", "ShieldMask", "SanitizeMask", "DegradedMask",
          "FormatMask"}},
        {"PhysicalDriveAuStatus",
         {"Unknown", "Unusable", "Missing", "Good", "Bad", "RaidRebuild",
          "RaidCopyback", "RaidOffline", "RaidFailed", "RaidOnline"}},
        {"LogicalDriveRaidType",
         {"RAID00", "RAID0", "RAID1", "RAID10", "RAID5", "RAID50", "RAID6",
          "RAID60", "RAID1E", "RAID1ERLQ0", "RAID1E0RLQ0"}},
        {"DiskWriteCachePolicy", {"Unchanged", "Enable", "Disable"}},
        {"LdReadCachePolicy", {"Off", "ReadAhead"}},
        {"LdWriteCachePolicy",
         {"WriteThrough", "ProtectedWriteBack", "UnprotectedWriteBack"}},
        {"EncryptType", {"None", "SED"}},
        {"CachePolicy",
         {"WriteThrough", "ProtectedWriteBack", "UnprotectedWriteBack",
          "NoReadAhead", "ReadAhead"}},
        {"CacheBypassMode", {"None", "Size", "All"}},
        {"CoercionMode", {"None", "Boundary128MiB", "Boundary1GiB"}},
        {"RebuildOperatingMode",
         {"Unknown", "PriorityRebuild", "PriorityIOPS"}},
        {"DetectionType",
         {"Disabled", "Enabled", "Aggressive",
          "RecoveryTimeLimitAndWriteRetryCount"}},
        {"CorrectiveAction", {"LogOnly", "LogAndTakeCorrectiveAction"}},
        {"PdDegradedMediaErrorThreshold",
         {"Every8Hours", "Every1Hour", "Every15Minutes", "Every5Minutes"}},
        {"BootMode", {"ContinueOnError", "SafeModeOnError"}},
        {"CacheOffloadEncryptionType", {"None", "AESXTS256"}},
        {"PCIeRefClkOverride",
         {"NoOverride", "Enabled", "Disabled", "BackplaneError"}},
        {"PCIePERSTOverride",
         {"NoOverride", "Deasserted", "Asserted", "BackplaneError"}},
        {"InitializationMode", {"FastMode", "FullMode"}},
        {"EraseType",
         {"Simple", "Normal", "Thorough", "CryptographicErase",
          "SanitizeOverwrite", "SanitizeBlockErase", "SanitizeFreezeLock",
          "SanitizeAntifreezeLock"}},
    };

// Strips the "<namespace><enumType>." prefix if present, otherwise returns
// the value unchanged (already plain, or a different/unknown enum type).
inline std::string plainValue(std::string_view enumType,
                              const std::string& value)
{
    std::string prefix =
        std::string(sl8EnumNamespace) + std::string(enumType) + ".";
    if (value.starts_with(prefix))
    {
        return value.substr(prefix.size());
    }
    return value;
}

// Accepts either the plain value or the legacy fully-qualified value.
// Unknown enum types are not validated (fail-open, preserves old behavior).
inline bool isValidEnumValue(std::string_view enumType,
                             const std::string& value)
{
    auto it = allowedEnumValues.find(enumType);
    if (it == allowedEnumValues.end())
    {
        return true;
    }
    std::string plain = plainValue(enumType, value);
    return std::find(it->second.begin(), it->second.end(), plain) !=
           it->second.end();
}

// Qualifies a plain enum value into the fully-qualified D-Bus string.
// Values already fully-qualified (legacy callers) are left unchanged.
inline std::string qualifyEnum(std::string_view enumType,
                               const std::string& value)
{
    if (value.starts_with(sl8EnumNamespace))
    {
        return value;
    }
    return std::string(sl8EnumNamespace) + std::string(enumType) + "." + value;
}

inline std::vector<std::string> qualifyEnumVector(
    std::string_view enumType, const std::vector<std::string>& values)
{
    std::vector<std::string> result;
    result.reserve(values.size());
    for (const auto& value : values)
    {
        result.push_back(qualifyEnum(enumType, value));
    }
    return result;
}

// Validates then qualifies in place; on failure, sets the Redfish error
// response and returns false.
inline bool validateAndQualifyEnum(
    crow::Response& res, std::string_view enumType, std::string_view paramName,
    std::string_view actionName, std::string& value)
{
    if (!isValidEnumValue(enumType, value))
    {
        messages::actionParameterValueNotInList(res, value, paramName,
                                                actionName);
        return false;
    }
    value = qualifyEnum(enumType, value);
    return true;
}

inline bool validateAndQualifyEnumVector(
    crow::Response& res, std::string_view enumType, std::string_view paramName,
    std::string_view actionName, std::vector<std::string>& values)
{
    for (const auto& value : values)
    {
        if (!isValidEnumValue(enumType, value))
        {
            messages::actionParameterValueNotInList(res, value, paramName,
                                                    actionName);
            return false;
        }
    }
    values = qualifyEnumVector(enumType, values);
    return true;
}

// Convenience overload for the common case where the enum type name and the
// JSON parameter name are identical.
inline bool validateAndQualifyEnum(
    crow::Response& res, std::string_view paramName,
    std::string_view actionName, std::string& value)
{
    return validateAndQualifyEnum(res, paramName, paramName, actionName, value);
}

} // namespace brcm_enum
} // namespace redfish
