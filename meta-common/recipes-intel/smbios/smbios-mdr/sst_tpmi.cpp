// Copyright (c) 2022 Intel Corporation
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#include "cpuinfo_utils.hpp"
#include "speed_select.hpp"

#include <sdbusplus/asio/property.hpp>
#include <sdbusplus/bus/match.hpp>
#include <sdbusplus/exception.hpp>
#include <sdbusplus/message/native_types.hpp>
#include <sdbusplus/unpack_properties.hpp>

#include <bitset>
#include <limits>
#include <optional>
#include <stdexcept>
#include <variant>

namespace cpu_info
{
namespace sst
{

/**
 * Singleton class which, when created, automatically starts watching for
 * relevant TPMI D-Bus data, and caches the properties locally for use by the
 * TPMI SST backend. Also takes care of automatically setting the D-Bus
 * properties to make the SST TPMI interface exclusively owned by the BMC.
 */
class TPMIDBusCache
{
  public:
    // Cache of com.intel.TPMI interface
    struct CPU
    {
        uint8_t address;
        uint8_t segment;
        uint8_t bus;
        uint8_t device;
        uint8_t function;
        uint8_t bar;
    };
    // Cache of com.intel.TPMI.Feature interface
    struct Feature
    {
        uint32_t offset;
        uint32_t instances;
        uint32_t size;
        bool enabled;
        bool inBandWrite;
        bool inBandRead;
        bool usePCS;
        bool locked;
    };

    constexpr static int sstTPMIID = 5;

  private:
    std::unique_ptr<sdbusplus::bus::match_t> interfacesAddedMatch;
    std::unique_ptr<sdbusplus::bus::match_t> interfacesRemovedMatch;
    std::map<int, CPU> cpus;
    std::map<int, Feature> features;

  public:
    /** Return the singleton TPMIDBusCache instance. */
    static TPMIDBusCache& getInstance()
    {
        static TPMIDBusCache instance;
        return instance;
    }

    /** Return a map of 0-based CPU index to CPU data */
    const std::map<int, CPU>& getCPUs() const
    {
        return cpus;
    }

    /** Return a map of 0-based CPU index to SST Feature data */
    const std::map<int, Feature>& getFeatures() const
    {
        return features;
    }

    enum MutableFeatureProperty
    {
        enabled,
        inBandWrite,
        inBandRead,
        usePCS,
        locked
    };

    static constexpr std::array<const char*, 5> mutableFeaturePropertyNames = {
        "Enabled", "InBandWriteAllowed", "InBandReadAllowed", "UsePCS",
        "Locked"};

    void setProperty(int index, MutableFeatureProperty property, bool value)
    {
        DEBUG_PRINT << "Setting property: index = " << index
                    << ", property = " << property
                    << ", value = " << static_cast<int>(value) << '\n';
        sdbusplus::asio::setProperty(
            *dbus::getConnection(), "com.intel.TPMI", sstObjectPath(index).str,
            "com.intel.TPMI.Feature", mutableFeaturePropertyNames[property],
            value, [index, property, value](std::error_code ec) {
                if (ec)
                {
                    std::cerr << "Failed to set SST property "
                              << mutableFeaturePropertyNames[property] << '\n';
                    return;
                }
                // Update the cached property value if the write succeeded,
                // instead of processing PropertiesChanged signals. This assumes
                // values would never be changed by other applications.
                auto& feature = getInstance().features.at(index);
                switch (property)
                {
                    case enabled:
                        feature.enabled = value;
                        break;
                    case inBandWrite:
                        feature.inBandWrite = value;
                        break;
                    case inBandRead:
                        feature.inBandRead = value;
                        break;
                    case usePCS:
                        feature.usePCS = value;
                        break;
                    case locked:
                        feature.locked = value;
                        break;
                }
            });
    }

    bool contains(int index)
    {
        return getCPUs().contains(index) && getFeatures().contains(index);
    }

  private:
    using Properties = std::vector<std::pair<
        std::string, std::variant<std::monostate, uint8_t, uint32_t, bool>>>;

    struct PathComponents
    {
        int cpuIndex;
        int featureID;
    };
    constexpr static int invalidPathComponent = -1;

    TPMIDBusCache()
    {
        DEBUG_PRINT << "Creating dbus cache\n";
        // Match InterfacesAdded and InterfacesRemoved for com.intel.TPMI and
        // com.intel.TPMI.Feature to know when to update and delete that data.
        interfacesAddedMatch = std::make_unique<sdbusplus::bus::match_t>(
            *dbus::getConnection(),
            sdbusplus::bus::match::rules::sender("com.intel.TPMI") +
                "type='signal',interface='org.freedesktop.DBus.ObjectManager'",
            handleTPMISignal);

        // Call GetSubTree for com.intel.TPMI and
        // com.intel.TPMI.Feature. Read all properties for CPUs and
        // entries with ID=5 (SST) and cache for future use.
        auto conn = dbus::getConnection();
        conn->async_method_call(
            handleGetTPMISubTree, "xyz.openbmc_project.ObjectMapper",
            "/xyz/openbmc_project/object_mapper",
            "xyz.openbmc_project.ObjectMapper", "GetSubTree", "/com/intel/tpmi",
            2,
            std::array<const char*, 2>{"com.intel.TPMI",
                                       "com.intel.TPMI.Feature"});
    }
    ~TPMIDBusCache()
    {}

    static void handleTPMISignal(sdbusplus::message::message& msg)
    {
        sdbusplus::message::object_path changedObject;
        msg.read(changedObject);

        std::optional<PathComponents> object = decodePath(changedObject);
        if (!object)
        {
            return;
        }
        if (object->featureID != invalidPathComponent &&
            object->featureID != sstTPMIID)
        {
            // SST TPMI_ID = 5.
            // If this path was for an Entry other than SST, ignore it.
            return;
        }

        const char* const signal = msg.get_member();
        if (signal == std::string_view("InterfacesAdded"))
        {
            std::vector<std::pair<std::string, Properties>>
                interfacesAndProperties;
            msg.read(interfacesAndProperties);

            for (const auto& [interfaceName, properties] :
                 interfacesAndProperties)
            {
                if (interfaceName == "com.intel.TPMI")
                {
                    getInstance().addCPU(object->cpuIndex, properties);
                }
                else if (interfaceName == "com.intel.TPMI.Feature")
                {
                    getInstance().addSSTFeature(object->cpuIndex, properties);
                }
            }
        }
        else if (signal == std::string_view("InterfacesRemoved"))
        {
            std::vector<std::string> interfaces;
            msg.read(interfaces);
            for (const auto& interface : interfaces)
            {
                if (interface == "com.intel.TPMI")
                {
                    getInstance().removeCPU(object->cpuIndex);
                }
                else if (interface == "com.intel.TPMI.Feature")
                {
                    getInstance().removeFeature(object->cpuIndex);
                }
            }
        }
    }

    static void handleGetTPMISubTree(
        std::error_code ec,
        const std::unordered_map<
            std::string,
            std::unordered_map<std::string, std::vector<std::string>>>& subTree)
    {
        if (ec)
        {
            std::cerr << "GetSubTree failed: " << ec.message() << '\n';
            return;
        }
        for (const auto& [path, services] : subTree)
        {
            std::optional<PathComponents> object = decodePath(path);
            if (!object)
            {
                continue;
            }
            if (object->featureID != invalidPathComponent &&
                object->featureID != sstTPMIID)
            {
                continue;
            }

            for (const auto& [serviceName, interfaces] : services)
            {
                for (const auto& interface : interfaces)
                {
                    bool isCPUInterface = false;
                    if (interface == "com.intel.TPMI")
                    {
                        isCPUInterface = true;
                    }
                    else if (interface != "com.intel.TPMI.Feature")
                    {
                        continue;
                    }

                    sdbusplus::asio::getAllProperties(
                        *dbus::getConnection(), serviceName, path, interface,
                        [isCPUInterface, cpuIndex = object->cpuIndex](
                            std::error_code ec, const Properties& properties) {
                            if (ec)
                            {
                                return;
                            }
                            if (isCPUInterface)
                            {
                                getInstance().addCPU(cpuIndex, properties);
                            }
                            else
                            {
                                getInstance().addSSTFeature(cpuIndex,
                                                            properties);
                            }
                        });
                }
            }
        }
    }

    /**
     * Extract the unique parts of a TPMI D-Bus object path (CPU Index and TPMI
     * Feature ID, if applicable).
     *
     * Object paths are expected to be of the form "/com/intel/tpmi/cpu0" or
     * "/com/intel/tpmi/cpu0/5", or else decoding will fail.
     *
     * @return  std::nullopt if path decoding failed, or a PathComponent struct
     *          if decoding succeeded. The featureID member will be set to -1 if
     *          the path corresponds to a CPU rather than a Feature.
     */
    static std::optional<PathComponents>
        decodePath(const sdbusplus::message::object_path& path)
    {
        PathComponents comps = {invalidPathComponent, invalidPathComponent};

        std::string name = path.filename();
        if (!name.starts_with("cpu"))
        {
            try
            {
                size_t pos;
                comps.featureID = std::stoi(name, &pos);
                if (comps.featureID < 0 ||
                    comps.featureID > std::numeric_limits<uint8_t>::max() ||
                    pos != name.length())
                {
                    return std::nullopt;
                }
                name = path.parent_path().filename();
            }
            catch (const std::invalid_argument& error)
            {
                return std::nullopt;
            }
        }

        // Should be named "cpuX" where X is a number
        if (!name.starts_with("cpu"))
        {
            return std::nullopt;
        }
        name.erase(0, 3);
        try
        {
            size_t pos;
            comps.cpuIndex = std::stoi(name, &pos);
            if (comps.cpuIndex < 0 || pos != name.length())
            {
                return std::nullopt;
            }
        }
        catch (const std::invalid_argument& error)
        {
            return std::nullopt;
        }

        return comps;
    }

    static sdbusplus::message::object_path sstObjectPath(int cpuIndex)
    {
        sdbusplus::message::object_path path("/com/intel/tpmi");
        path /= "cpu" + std::to_string(cpuIndex);
        path /= std::to_string(sstTPMIID);
        return path;
    }

    void addCPU(int index, const Properties& properties)
    {
        DEBUG_PRINT << "caching cpu " << index << '\n';
        CPU cpu;
        try
        {
            sdbusplus::unpackProperties(properties, "Address", cpu.address,
                                        "Segment", cpu.segment, "Bus", cpu.bus,
                                        "Device", cpu.device, "Function",
                                        cpu.function, "BARIndex", cpu.bar);
        }
        catch (const sdbusplus::exception::UnpackPropertyError& error)
        {
            std::cerr << "Unexpected CPU property type: " << error.what()
                      << '\n';
            removeCPU(index);
            return;
        }
        DEBUG_PRINT << "Successfully added CPU\n";
        cpus[index] = cpu;
    }

    void addSSTFeature(int index, const Properties& properties)
    {
        DEBUG_PRINT << "caching SST object\n";
        Feature feature;

        try
        {
            sdbusplus::unpackProperties(
                properties, "Offset", feature.offset, "Instances",
                feature.instances, "Size", feature.size, "Enabled",
                feature.enabled, "InBandReadAllowed", feature.inBandRead,
                "InBandWriteAllowed", feature.inBandWrite, "UsePCS",
                feature.usePCS, "Locked", feature.locked);
        }
        catch (const sdbusplus::exception::UnpackPropertyError& error)
        {
            std::cerr << "Unexpected Feature property type: " << error.what()
                      << '\n';
            removeFeature(index);
            return;
        }

        // Enable it (should be enabled by default)
        if (!feature.enabled)
        {
            if (!feature.locked)
            {
                setProperty(index, TPMIDBusCache::enabled, true);
            }
            else
            {
                std::cerr << "SST locked and disabled - can't use it\n";
                removeFeature(index);
                return;
            }
        }
        // Use TPMI over PCS (PCS doesn't exist any more for CPUs that support
        // TPMI so this should never need to be set)
        if (feature.usePCS)
        {
            if (!feature.locked)
            {
                setProperty(index, TPMIDBusCache::usePCS, false);
            }
            else
            {
                std::cerr << "SST locked and usePCS - can't use it\n";
                removeFeature(index);
                return;
            }
        }

        DEBUG_PRINT << "Successfully added Feature\n";
        features[index] = feature;
    }

    void removeCPU(int index)
    {
        DEBUG_PRINT << "Removing cpu object\n";
        cpus.erase(index);
    }

    void removeFeature(int index)
    {
        DEBUG_PRINT << "Removing feature object\n";
        features.erase(index);
    }
};

class WakeOnPECIManager
{
    bool peciWoken = false;

    uint8_t cpuAddr;
    WakePolicy wakePolicy;

  public:
    WakeOnPECIManager(uint8_t cpuAddr_, WakePolicy wakePolicy_) :
        cpuAddr(cpuAddr_), wakePolicy(wakePolicy_)
    {}
    ~WakeOnPECIManager()
    {
        try
        {
            if (peciWoken)
            {
                setWakeOnPECI(false);
            }
        }
        catch (const PECIError&)
        {}
    }

    template <typename PECIOp>
    std::pair<EPECIStatus, uint8_t> peciOpWithWakeRetry(PECIOp&& peciOp)
    {
        uint8_t cc;
        EPECIStatus status = peciOp(&cc);

        constexpr int ccUnavailResource = 0x82;
        if (wakePolicy == wakeAllowed && status == PECI_CC_SUCCESS &&
            cc == ccUnavailResource)
        {
            setWakeOnPECI(true);
            status = peciOp(&cc);
        }

        return {status, cc};
    }

    void setWakeOnPECI(bool enable)
    {
        constexpr int pkgIDIndex = 0;
        constexpr int diePresenceParam = 7;
        constexpr int wakeOnPECIIndex = 5;

        // Cache the die masks for each CPU to avoid extra unnecessary reads.
        static std::map<uint8_t, std::bitset<32>> dieMasks;

        if (enable == peciWoken)
        {
            return;
        }

        uint8_t cc;
        EPECIStatus status;
        if (!dieMasks.contains(cpuAddr))
        {
            uint32_t data;
            status = peci_RdPkgConfig(cpuAddr, pkgIDIndex, diePresenceParam,
                                      sizeof(data),
                                      reinterpret_cast<uint8_t*>(&data), &cc);
            if (!checkPECIStatus(status, cc))
            {
                throw PECIError("Failed to read die mask");
            }
            dieMasks[cpuAddr] = data;
            DEBUG_PRINT << "Read die mask " << std::hex << data << std::dec
                        << '\n';
        }

        std::cerr << "Setting Wake-on-PECI=" << enable << '\n';

        const std::bitset<32>& dieMask = dieMasks[cpuAddr];

        for (uint8_t i = 0; i < dieMask.size(); ++i)
        {
            if (!dieMask.test(i))
            {
                continue;
            }
            uint32_t unusedData;
            int tries = 0;
            do
            {
                status = peci_WrPkgConfig_dom(cpuAddr, i, wakeOnPECIIndex,
                                              enable ? 1 : 0, &unusedData,
                                              sizeof(unusedData), &cc);
            } while (status == PECI_CC_TIMEOUT && ++tries <= 5);

            if (tries > 1)
            {
                DEBUG_PRINT << "Tried to set Wake-On-PECI " << std::hex
                            << cpuAddr << std::dec << ":" << static_cast<int>(i)
                            << " " << tries << " times\n";
            }

            if (!checkPECIStatus(status, cc))
            {
                throw PECIError("Failed to set Wake-On-PECI mode bit");
            }
            if (enable)
            {
                // Set flag if any domains succeeded
                peciWoken = true;
            }
        }
        if (!enable)
        {
            // Only clear flag if all domains succeeded
            peciWoken = false;
        }
    }
};

/**
 * Represents a view on the raw SST memory space.
 */
class SSTRegisterSet
{
    constexpr static uint64_t invalidRead = 0x00000000FFFFFFFFull;

    TPMIDBusCache& dbusCache = TPMIDBusCache::getInstance();
    const TPMIDBusCache::CPU* cpu;
    const TPMIDBusCache::Feature* feature;
    uint8_t cpuIndex;
    WakeOnPECIManager peciManager;

    unsigned ppOffset(unsigned instance)
    {
        return mask<unsigned>(header(instance), 24, 31) * 8;
    }

    size_t ppLevelOffset(unsigned instance, unsigned level)
    {
        auto loBit = level * 8;
        auto ppLevelOffset =
            mask<size_t>(ppOffset1(instance), loBit, loBit + 7);
        return ppOffset(instance) + ppLevelOffset * 8;
    }

    std::tuple<uint64_t, EPECIStatus, uint8_t> readNoThrow(unsigned instance,
                                                           size_t offset)
    {
        offset += feature->offset;
        offset += feature->size * instance;

        uint64_t data;
        auto [status, cc] = peciManager.peciOpWithWakeRetry(std::bind_front(
            peci_RdEndPointConfigMmio, cpu->address, cpu->segment, cpu->bus,
            cpu->device, cpu->function, cpu->bar, MMIO_QWORD_OFFSET, offset,
            sizeof(data), reinterpret_cast<uint8_t*>(&data)));
        return {data, status, cc};
    }

    uint64_t cachedRead(unsigned instance, size_t offset)
    {
        // Cache some of the registers to avoid reading RO data multiple times.
        // {CPU index, TPMI instance, register offset} -> register value
        static std::map<std::tuple<uint8_t, unsigned, size_t>, uint64_t>
            cachedRegs;

        auto key = std::make_tuple(cpuIndex, instance, offset);
        auto it = cachedRegs.find(key);
        if (it != cachedRegs.end())
        {
            return it->second;
        }
        uint64_t value = read(instance, offset);
        cachedRegs[key] = value;
        return value;
    }

  public:
    SSTRegisterSet(uint8_t _cpuIndex, WakePolicy wakePolicy) :
        cpuIndex(_cpuIndex), peciManager(cpuIndex + MIN_CLIENT_ADDR, wakePolicy)
    {
        DEBUG_PRINT << "SSTRegisterSet constructor\n";
        if (!dbusCache.contains(cpuIndex))
        {
            throw PECIError("Unavailable");
        }
        cpu = &dbusCache.getCPUs().at(cpuIndex);
        feature = &dbusCache.getFeatures().at(cpuIndex);
    }

    uint64_t read(unsigned instance, size_t offset)
    {
        if (instance >= feature->instances)
        {
            throw std::out_of_range("Invalid instance");
        }

        auto [data, status, cc] = readNoThrow(instance, offset);
        if (!checkPECIStatus(status, cc))
        {
            throw PECIError("MMIO Read failed");
        }
        return data;
    }

    void write(unsigned instance, size_t offset, uint64_t data)
    {
        if (instance >= feature->instances)
        {
            throw std::out_of_range("Invalid instance");
        }

        offset += feature->offset;
        offset += feature->size * instance;

        auto [status, cc] = peciManager.peciOpWithWakeRetry(std::bind_front(
            peci_WrEndPointConfigMmio, cpu->address, cpu->segment, cpu->bus,
            cpu->device, cpu->function, cpu->bar, MMIO_QWORD_OFFSET, offset,
            sizeof(data), data));
        if (!checkPECIStatus(status, cc))
        {
            throw PECIError("MMIO Write failed");
        }
    }

    std::vector<unsigned> validInstances()
    {
        // The valid instances may be non-contiguous. So we read the first DWORD
        // of each possible instance to check if it's valid. We should either
        // get valid data or a 0x90 CC. Other PECI errors are unexpected and so
        // will trigger a throw. All F's in the data are not expected but that's
        // what is returned to the in-band host SW for invalid instances, so
        // we'll include that case for completeness.
        std::vector<unsigned> valid;
        for (size_t i = 0; i < feature->instances; ++i)
        {
            auto [data, status, cc] = readNoThrow(i, 0);
            if (status == PECI_CC_SUCCESS && cc == 0x90)
            {
                continue;
            }
            else if (!checkPECIStatus(status, cc))
            {
                throw PECIError("MMIO Read failed");
            }
            else if (data == invalidRead)
            {
                continue;
            }
            valid.push_back(i);
        }
        return valid;
    }

    uint64_t header(unsigned instance)
    {
        return cachedRead(instance, 0);
    }

    uint64_t ppHeader(unsigned instance)
    {
        // Not cacheable - some fields may change based on BIOS knob.
        return read(instance, ppOffset(instance));
    }

    uint64_t ppOffset0(unsigned instance)
    {
        return cachedRead(instance, ppOffset(instance) + 8);
    }

    uint64_t ppOffset1(unsigned instance)
    {
        return cachedRead(instance, ppOffset(instance) + 8 * 2);
    }

    uint64_t ppControl(unsigned instance)
    {
        return read(instance, ppOffset(instance) + 8 * 3);
    }

    uint64_t ppStatus(unsigned instance)
    {
        return read(instance, ppOffset(instance) + 8 * 4);
    }

    uint64_t bfInfo0(unsigned instance, unsigned level)
    {
        auto bfOffset = mask<size_t>(ppOffset0(instance), 8, 15);
        return cachedRead(instance,
                          ppLevelOffset(instance, level) + bfOffset * 8);
    }

    uint64_t bfInfo1(unsigned instance, unsigned level)
    {
        auto bfOffset = mask<size_t>(ppOffset0(instance), 8, 15);
        return cachedRead(instance,
                          ppLevelOffset(instance, level) + bfOffset * 8 + 8);
    }

    uint64_t tfInfo0(unsigned instance, unsigned level)
    {
        auto tfOffset = mask<size_t>(ppOffset0(instance), 16, 23);
        return cachedRead(instance,
                          ppLevelOffset(instance, level) + tfOffset * 8);
    }

    uint64_t ppInfo1(unsigned instance, unsigned level)
    {
        // Not cacheable - resolved cores can change by changed by BIOS.
        return read(instance, ppLevelOffset(instance, level) + 8);
    }

    uint64_t ppInfo2(unsigned instance, unsigned level)
    {
        // Not cacheable - resolved cores can change by changed by BIOS.
        return read(instance, ppLevelOffset(instance, level) + 8 * 2);
    }

    uint64_t ppInfo4(unsigned instance, unsigned level)
    {
        return read(instance, ppLevelOffset(instance, level) + 8 * 4);
    }

    uint64_t ppInfo10(unsigned instance, unsigned level)
    {
        return read(instance, ppLevelOffset(instance, level) + 8 * 10);
    }

    uint64_t ppInfo11(unsigned instance, unsigned level)
    {
        return read(instance, ppLevelOffset(instance, level) + 8 * 11);
    }

    void ppControl(unsigned instance, uint64_t value)
    {
        write(instance, ppOffset(instance) + 8 * 3, value);
    }
};

class SSTTPMI : public SSTInterface
{
  private:
    int address;
    int cpuIndex;
    TPMIDBusCache& dbusCache = TPMIDBusCache::getInstance();
    std::unique_ptr<SSTRegisterSet> intf;
    WakePolicy wakePolicy;

    static constexpr int mhzPerRatio = 100;

  public:
    SSTTPMI(int _address, CPUModel, WakePolicy wakePolicy_) :
        address(_address), cpuIndex(address - MIN_CLIENT_ADDR),
        wakePolicy(wakePolicy_)
    {
        DEBUG_PRINT << "SSTTPMI constructor\n";
        if (dbusCache.contains(cpuIndex))
        {
            intf = std::make_unique<SSTRegisterSet>(cpuIndex, wakePolicy);
        }
    }
    ~SSTTPMI()
    {}

    bool ready() override
    {
        if (!dbusCache.contains(cpuIndex))
        {
            DEBUG_PRINT << "ready(): didn't find cached sst object\n";
            return false;
        }

        if (!intf)
        {
            intf = std::make_unique<SSTRegisterSet>(cpuIndex, wakePolicy);
        }

        const TPMIDBusCache::Feature& sst =
            dbusCache.getFeatures().at(cpuIndex);
        // The cache object may exist but the property writes haven't gone
        // through yet
        return sst.enabled && !sst.usePCS;
    }

    bool supportsControl() override
    {
        // SST_PP_HEADER.DYNAMIC_SWITCHING
        return mask<bool>(intf->ppHeader(0), 42, 42);
    }

    unsigned currentLevel() override
    {
        // SST_PP_LEVEL
        return mask<unsigned>(intf->ppStatus(0), 0, 2);
    }

    unsigned maxLevel() override
    {
        // SST_PP_LEVEL_EN_MASK
        // Return the index of the most significant set bit
        std::bitset<8> levelMask = mask(intf->ppHeader(0), 12, 19);
        for (unsigned i = 7; i > 0; --i)
        {
            if (levelMask[i])
            {
                return i;
            }
        }
        return 0;
    }

    bool ppEnabled() override
    {
        // CAPABILITY_MASK[1]
        return mask(intf->header(0), 9, 9);
    }

    bool levelSupported(unsigned level) override
    {
        // SST_PP_LEVEL_EN_MASK
        std::bitset<8> levelMask = mask(intf->ppHeader(0), 12, 19);
        return levelMask.test(level);
    }

    bool bfSupported(unsigned level) override
    {
        // FEATURE_SUPPORTED
        return mask(intf->bfInfo0(0, level), 12, 12);
    }

    bool tfSupported(unsigned level) override
    {
        // FEATURE_SUPPORTED
        return mask(intf->tfInfo0(0, level), 12, 12);
    }

    bool bfEnabled(unsigned level) override
    {
        if (currentLevel() != level)
        {
            throw PECIError("Cannot get feature state for non-current level");
        }
        // FEATURE_STATE[0]
        return mask(intf->ppStatus(0), 8, 8);
    }

    bool tfEnabled(unsigned level) override
    {
        if (currentLevel() != level)
        {
            throw PECIError("Cannot get feature state for non-current level");
        }
        // FEATURE_STATE[1]
        return mask(intf->ppStatus(0), 9, 9);
    }

    unsigned tdp(unsigned level) override
    {
        // TDP
        auto tdp = mask<unsigned>(intf->ppInfo1(0, level), 32, 46);
        // TDP is in 1/8 W unit.
        return tdp / 8;
    }

    unsigned coreCount(unsigned level) override
    {
        unsigned count = 0;

        forEachComputeInstance(level, [this, level, &count](unsigned instance) {
            // RESOLVED_CORE_COUNT
            count += mask<unsigned>(intf->ppInfo1(instance, level), 8, 15);
        });

        return count;
    }

    std::vector<unsigned> enabledCoreList(unsigned level) override
    {
        return gatherCoreList(level, &SSTRegisterSet::ppInfo2);
    }

    std::vector<TurboEntry> sseTurboProfile(unsigned level) override
    {
        auto trlCores = intf->ppInfo10(0, level);
        auto sseLimits = intf->ppInfo4(0, level);

        std::vector<TurboEntry> turboSpeeds;
        constexpr int maxTFBuckets = 8;
        for (int i = 0; i < maxTFBuckets; ++i)
        {
            size_t bucketCount = trlCores & 0xFF;
            int bucketSpeed = sseLimits & 0xFF;
            if (bucketCount != 0 && bucketSpeed != 0)
            {
                turboSpeeds.push_back({bucketSpeed * mhzPerRatio, bucketCount});
            }
            trlCores >>= 8;
            sseLimits >>= 8;
        }
        return turboSpeeds;
    }

    unsigned p1Freq(unsigned level) override
    {
        // P1_CORE_RATIO
        return mask<unsigned>(intf->ppInfo11(0, level), 8, 15) * mhzPerRatio;
    }

    unsigned p0Freq(unsigned level) override
    {
        // P0_CORE_RATIO
        return mask<unsigned>(intf->ppInfo11(0, level), 0, 7) * mhzPerRatio;
    }

    unsigned prochotTemp(unsigned level) override
    {
        // T_PROCHOT
        return mask<unsigned>(intf->ppInfo1(0, level), 47, 54);
    }

    std::vector<unsigned int> bfHighPriorityCoreList(unsigned level) override
    {
        return gatherCoreList(level, &SSTRegisterSet::bfInfo1);
    }

    unsigned bfHighPriorityFreq(unsigned level) override
    {
        // P1_HI
        return mask<unsigned>(intf->bfInfo0(0, level), 13, 20) * mhzPerRatio;
    }

    unsigned bfLowPriorityFreq(unsigned level) override
    {
        // P1_LO
        return mask<unsigned>(intf->bfInfo0(0, level), 21, 28) * mhzPerRatio;
    }

    void setBfEnabled(bool enable) override
    {
        // FEATURE_STATE[0]
        constexpr uint64_t bfBit = bit(8);
        setAllInstances(bfBit, enable ? bfBit : 0, 32, 34);
    }

    void setTfEnabled(bool enable) override
    {
        // FEATURE_STATE[1]
        constexpr uint64_t tfBit = bit(9);
        setAllInstances(tfBit, enable ? tfBit : 0, 35, 37);
    }

    void setCurrentLevel(unsigned level) override
    {
        // SST_PP_LEVEL
        setAllInstances(0x7, level, 4, 7);
    }

  private:
    void setAllInstances(uint64_t fieldMask, uint64_t value, unsigned errBitLo,
                         unsigned errBitHi)
    {
        for (unsigned instance : intf->validInstances())
        {
            uint64_t status = intf->ppControl(instance);
            status &= ~fieldMask;
            status |= value;
            intf->ppControl(instance, status);
            status = intf->ppStatus(instance);
            auto error = mask<int>(status, errBitLo, errBitHi);
            if (error != 0)
            {
                throw PECIError(std::to_string(error));
            }
        }
    }

    void forEachComputeInstance(unsigned level,
                                std::function<void(unsigned)> cb)
    {
        for (unsigned instance : intf->validInstances())
        {
            uint64_t ppInfo1 = intf->ppInfo1(instance, level);
            // RESOLVED_CORE_COUNT
            uint8_t coreCount = mask<uint8_t>(ppInfo1, 8, 15);
            if (coreCount == 0)
            {
                // TPMI architecture defines that compute dies come before IO
                // dies, so once we encounter an instance without cores, we can
                // stop.
                break;
            }
            cb(instance);
        }
    }

    using SSTRegister = uint64_t (SSTRegisterSet::*)(unsigned instance,
                                                     unsigned level);
    std::vector<unsigned> gatherCoreList(unsigned level, SSTRegister reg)
    {
        std::vector<unsigned> coreList;
        forEachComputeInstance(level, [this, level, reg,
                                       &coreList](unsigned instance) {
            std::bitset<64> coreMask = std::invoke(reg, intf, instance, level);
            std::vector<unsigned> instanceCoreList =
                convertMaskToList(coreMask);
            // ID of a core uses upper two bits for Die ID, and therefore 64
            // core IDs per die. Even if a core has less than 64 cores, the IDs
            // will follow this pattern. i.e Cdie0 has core IDs from 0 up to 63,
            // Cdie1 has core ID from 64 up to 127. So we need to offset the
            // core list from each instance based on this.
            std::for_each(instanceCoreList.begin(), instanceCoreList.end(),
                          [instance](unsigned& x) { x += 64 * instance; });
            coreList.insert(coreList.end(), instanceCoreList.begin(),
                            instanceCoreList.end());
        });
        return coreList;
    }
};

static std::unique_ptr<SSTInterface> createTPMI(int address, CPUModel model,
                                                WakePolicy wakePolicy)
{
    DEBUG_PRINT << "createTPMI\n";
    if (model == gnr || model == gnrd || model == srf)
    {
        return std::make_unique<SSTTPMI>(address, model, wakePolicy);
    }
    return nullptr;
}
SSTProviderRegistration(createTPMI);

} // namespace sst
} // namespace cpu_info
