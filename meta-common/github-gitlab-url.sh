#!/bin/sh

sed -i 's/git@github.com\/intel-collab\/firmware.bmc.openbmc.applications.at-scale-debug.git;protocol=ssh;branch=main/git@git.ami.com\/core\/oe\/advanced-features\/firmware.bmc.openbmc.applications.at-scale-debug.git;protocol=ssh;branch=main/g' openbmc-meta-intel/meta-common/recipes-core/at-scale-debug/at-scale-debug_git.bb

sed -i 's/git@github.com\/intel-collab\/firmware.bmc.openbmc.libraries.libespi.git;protocol=ssh;branch=main/git@git.ami.com\/core\/oe\/common\/firmware.bmc.openbmc.libraries.libespi.git;protocol=ssh;branch=main/g' openbmc-meta-intel/meta-common/recipes-core/libespi/libespi_git.bb

sed -i 's/git@github.com\/intel-collab\/firmware.bmc.openbmc.applications.mtd-util.git;protocol=ssh;branch=main/git@git.ami.com\/core\/oe\/common\/firmware.bmc.openbmc.applications.mtd-util.git;protocol=ssh;branch=main/g' openbmc-meta-intel/meta-common/recipes-devtools/mtd-util/mtd-util.bb

sed -i 's/git@github.com\/intel-collab\/firmware.bmc.openbmc.applications.host-misc-comm-manager;protocol=ssh;branch=main/git@git.ami.com\/core\/oe\/advanced-features\/firmware.bmc.openbmc.applications.host-misc-comm-manager;protocol=ssh;branch=main/g' openbmc-meta-intel/meta-common/recipes-intel/host-misc-comm-manager/host-misc-comm-manager_git.bb

sed -i 's/git@github.com\/intel-collab\/firmware.bmc.openbmc.applications.intel-pfr-signing-utility.git;protocol=ssh;branch=main/git@git.ami.com\/core\/oe\/advanced-features\/firmware.bmc.openbmc.applications.intel-pfr-signing-utility.git;protocol=ssh;branch=main/g' openbmc-meta-intel/meta-common/recipes-intel/intel-pfr/intel-pfr-signing-utility-native.bb

sed -i 's/git@github.com\/intel-collab\/firmware.bmc.openbmc.applications.psu-manager.git;protocol=ssh;branch=main/git@git.ami.com\/core\/oe\/advanced-features\/firmware.bmc.openbmc.applications.psu-manager.git;protocol=ssh;branch=main/g' openbmc-meta-intel/meta-common/recipes-intel/psu-manager/psu-manager.bb

sed -i 's/git@github.com\/intel-collab\/os.linux.kernel.openbmc.linux.git;protocol=ssh;branch=${KBRANCH}/git@git.ami.com\/core\/oe\/common\/os.linux.kernel.openbmc.linux.git;protocol=ssh;branch=${KBRANCH}/g' openbmc-meta-intel/meta-common/recipes-kernel/linux/linux-aspeed_%.bbappend

sed -i 's/git@github.com\/intel-collab\/firmware.bmc.openbmc.applications.node-manager-proxy.git;protocol=ssh;branch=main/git@git.ami.com\/core\/oe\/advanced-features\/firmware.bmc.openbmc.applications.node-manager-proxy.git;protocol=ssh;branch=main/g' openbmc-meta-intel/meta-common/recipes-phosphor/ipmi/phosphor-node-manager-proxy_git.bb

sed -i 's/git@github.com\/intel-collab\/firmware.bmc.openbmc.libraries.libmctp.git;protocol=ssh;branch=main/git@git.ami.com\/core\/oe\/advanced-features\/firmware.bmc.openbmc.libraries.libmctp.git;protocol=ssh;branch=main/g' openbmc-meta-intel/meta-common/recipes-phosphor/pmci/libmctp-intel_git.bb

sed -i 's/git@github.com\/intel-collab\/firmware.bmc.openbmc.libraries.libpldm.git;protocol=ssh;branch=main/git@git.ami.com\/core\/oe\/advanced-features\/firmware.bmc.openbmc.libraries.libpldm.git;protocol=ssh;branch=main/g' openbmc-meta-intel/meta-common/recipes-phosphor/pmci/libpldm-intel_git.bb

sed -i 's/git@github.com\/intel-collab\/firmware.bmc.openbmc.libraries.mctp-wrapper.git;protocol=ssh;branch=main/git@git.ami.com\/core\/oe\/advanced-features\/firmware.bmc.openbmc.libraries.mctp-wrapper.git;protocol=ssh;branch=main/g' openbmc-meta-intel/meta-common/recipes-phosphor/pmci/mctp-wrapper.bb

sed -i 's/git@github.com\/intel-collab\/firmware.bmc.openbmc.applications.mctpd.git;protocol=ssh;branch=main/git@git.ami.com\/core\/oe\/advanced-features\/firmware.bmc.openbmc.applications.mctpd.git;protocol=ssh;branch=main/g' openbmc-meta-intel/meta-common/recipes-phosphor/pmci/mctpd.bb

sed -i 's/git@github.com\/intel-collab\/firmware.bmc.openbmc.libraries.mctpwplus.git;protocol=ssh;branch=main/git@git.ami.com\/core\/oe\/advanced-features\/firmware.bmc.openbmc.libraries.mctpwplus.git;protocol=ssh;branch=main/g' openbmc-meta-intel/meta-common/recipes-phosphor/pmci/mctpwplus.bb

sed -i 's/git@github.com\/intel-collab\/firmware.bmc.openbmc.applications.nvme-mi-daemon.git;protocol=ssh;branch=main/git@git.ami.com\/core\/oe\/advanced-features\/firmware.bmc.openbmc.applications.nvme-mi-daemon.git;protocol=ssh;branch=main/g' openbmc-meta-intel/meta-common/recipes-phosphor/pmci/nvmemi-daemon.bb

sed -i 's/git@github.com\/intel-collab\/firmware.bmc.openbmc.applications.pldmd.git;protocol=ssh;branch=main/git@git.ami.com\/core\/oe\/advanced-features\/firmware.bmc.openbmc.applications.pldmd.git;protocol=ssh;branch=main/g' openbmc-meta-intel/meta-common/recipes-phosphor/pmci/pldmd.bb

sed -i 's/git@github.com\/intel-collab\/firmware.bmc.openbmc.applications.pmci-launcher.git;protocol=ssh;branch=main/git@git.ami.com\/core\/oe\/advanced-features\/firmware.bmc.openbmc.applications.pmci-launcher.git;protocol=ssh;branch=main/g' openbmc-meta-intel/meta-common/recipes-phosphor/pmci/pmci-launcher.bb

sed -i 's/git@github.com\/intel-collab\/firmware.bmc.openbmc.applications.provisioning-mode-manager.git;protocol=ssh;branch=main/git@git.ami.com\/core\/oe\/advanced-features\/firmware.bmc.openbmc.applications.provisioning-mode-manager.git;protocol=ssh;branch=main/g' openbmc-meta-intel/meta-common/recipes-phosphor/prov-mode-mgr/prov-mode-mgr_git.bb

sed -i 's/git@github.com\/intel-collab\/firmware.bmc.openbmc.applications.security-manager.git;protocol=ssh;branch=main/git@git.ami.com\/core\/oe\/common\/firmware.bmc.openbmc.applications.security-manager.git;protocol=ssh;branch=main/g' openbmc-meta-intel/meta-common/recipes-phosphor/security-manager/security-manager_git.bb

sed -i 's/git@github.com\/intel-collab\/firmware.bmc.openbmc.applications.settings-manager.git;protocol=ssh;branch=main/git@git.ami.com\/core\/oe\/advanced-features\/firmware.bmc.openbmc.applications.settings-manager.git;protocol=ssh;branch=main/g' openbmc-meta-intel/meta-common/recipes-phosphor/settings/settings_git.bb

sed -i 's/git@github.com\/intel-collab\/firmware.bmc.openbmc.applications.special-mode-manager.git;protocol=ssh;branch=main/git@git.ami.com\/core\/oe\/advanced-features\/firmware.bmc.openbmc.applications.special-mode-manager.git;protocol=ssh;branch=main/g' openbmc-meta-intel/meta-common/recipes-phosphor/special-mode-mgr/special-mode-mgr_git.bb

sed -i 's/git@github.com\/intel-collab\/firmware.bmc.openbmc.applications.virtual-media.git;protocol=ssh;branch=main/git@git.ami.com\/core\/oe\/common\/firmware.bmc.openbmc.applications.virtual-media.git;protocol=ssh;branch=main/g' openbmc-meta-intel/meta-common/recipes-phosphor/virtual-media/virtual-media.bb

sed -i 's/git@github.com\/intel-collab\/firmware.bmc.openbmc.libraries.ipmi-providers.git;protocol=ssh;branch=main/git@git.ami.com\/core\/oe\/common\/firmware.bmc.openbmc.libraries.ipmi-providers.git;protocol=ssh;branch=main/g' openbmc-meta-intel/meta-internal/recipes-core/ipmi/ipmi-providers.bb

sed -i 's/git@github.com\/intel-collab\/firmware.bmc.openbmc.applications.crashdump-add-in-card.git;protocol=ssh;branch=main/git@git.ami.com\/core\/oe\/advanced-features\/firmware.bmc.openbmc.applications.crashdump-add-in-card.git;protocol=ssh;branch=main/g' openbmc-meta-intel/meta-internal/recipes-intel/aic-crashdump/aic-crashdump.bb

sed -i 's/git@github.com\/intel-collab\/firmware.bmc.openbmc.applications.bmc-collector.git;protocol=ssh;branch=main/git@git.ami.com\/core\/oe\/advanced-features\/firmware.bmc.openbmc.applications.bmc-collector.git;protocol=ssh;branch=main/g' openbmc-meta-intel/meta-internal/recipes-intel/bmc-collector/bmc-collector_git.bb

sed -i 's/git@github.com\/intel-collab\/firmware.bmc.openbmc.applications.cups-service.git;protocol=ssh;branch=main/git@git.ami.com\/core\/oe\/advanced-features\/firmware.bmc.openbmc.applications.cups-service.git;protocol=ssh;branch=main/g' openbmc-meta-intel/meta-internal/recipes-intel/cups/cups-service.bb

sed -i 's/git@github.com\/intel-collab\/firmware.bmc.openbmc.applications.cups-service.git;protocol=ssh;branch=egs/git@git.ami.com\/core\/oe\/advanced-features\/firmware.bmc.openbmc.applications.cups-service.git;protocol=ssh;branch=egs/g' openbmc-meta-intel/meta-internal/recipes-intel/cups/cups-service.bb

sed -i 's/git@github.com\/intel-collab\/firmware.bmc.openbmc.applications.modular-system.git;protocol=ssh;branch=main/git@git.ami.com\/core\/oe\/advanced-features\/firmware.bmc.openbmc.applications.modular-system.git;protocol=ssh;branch=main/g' openbmc-meta-intel/meta-internal/recipes-intel/modular-system/modular-system_git.bb

sed -i 's/git@github.com\/intel-collab\/firmware.bmc.openbmc.applications.node-manager.git;protocol=ssh;branch=main/git@git.ami.com\/core\/oe\/common\/firmware.bmc.openbmc.applications.node-manager.git;protocol=ssh;branch=main/g' openbmc-meta-intel/meta-internal/recipes-intel/node-manager/node-manager_git.bb

sed -i 's/git@github.com\/intel-collab\/firmware.bmc.openbmc.applications.optane-cxl.git;protocol=ssh;branch=main/git@git.ami.com\/core\/oe\/advanced-features\/firmware.bmc.openbmc.applications.optane-cxl.git;protocol=ssh;branch=main/g' openbmc-meta-intel/meta-internal/recipes-intel/optane-cxl/optane-cxl_git.bb

sed -i 's/git@github.com\/intel-collab\/firmware.bmc.openbmc.applications.vr-config-manager.git;protocol=ssh;branch=main/git@git.ami.com\/core\/oe\/advanced-features\/firmware.bmc.openbmc.applications.vr-config-manager.git;protocol=ssh;branch=main/g' openbmc-meta-intel/meta-internal/recipes-intel/vr/vr-manager_git.bb

sed -i 's/git@github.com\/intel-collab\/firmware.bmc.openbmc.libraries.libpmt.git;protocol=ssh;branch=main/git@git.ami.com\/core\/oe\/advanced-features\/firmware.bmc.openbmc.libraries.libpmt.git;protocol=ssh;branch=main/g' openbmc-meta-intel/meta-internal/recipes-phosphor/pmt/libpmt_git.bb

sed -i 's/git@github.com\/intel-collab\/firmware.bmc.openbmc.applications.platform-monitoring-technology.git;protocol=ssh;branch=main/git@git.ami.com\/core\/oe\/advanced-features\/firmware.bmc.openbmc.applications.platform-monitoring-technology.git;protocol=ssh;branch=main/g' openbmc-meta-intel/meta-internal/recipes-phosphor/pmt/pmt_git.bb

sed -i 's/git@github.com\/intel-collab\/firmware.bmc.openbmc.applications.bmc-assisted-fru-isolation.git;branch=main;protocol=ssh/git@git.ami.com\/core\/oe\/advanced-features\/firmware.bmc.openbmc.applications.bmc-assisted-fru-isolation.git;branch=main;protocol=ssh/g' openbmc-meta-intel/meta-restricted/recipes-core/bafi/bafi.bb

sed -i 's/git@github.com\/intel-collab\/firmware.bmc.openbmc.applications.crashdump.git;branch=egs;protocol=ssh/git@git.ami.com\/core\/oe\/advanced-features\/firmware.bmc.openbmc.applications.crashdump.git;branch=egs;protocol=ssh/g' openbmc-meta-intel/meta-restricted/recipes-core/crashdump/crashdump_git.bb

sed -i 's/git@github.com\/intel-collab\/firmware.bmc.openbmc.applications.host-memory.git;protocol=ssh;branch=main/git@git.ami.com\/core\/oe\/advanced-features\/firmware.bmc.openbmc.applications.host-memory.git;protocol=ssh;branch=main/g' openbmc-meta-intel/meta-restricted/recipes-core/host-memory/host-memory_git.bb

sed -i 's/git@github.com\/intel-collab\/firmware.bmc.openbmc.applications.memory-error-collector.git;protocol=ssh;branch=main/git@git.ami.com\/core\/oe\/advanced-features\/firmware.bmc.openbmc.applications.memory-error-collector.git;protocol=ssh;branch=main/g' openbmc-meta-intel/meta-restricted/recipes-core/memory-error-collector/memory-error-collector.bb

sed -i 's/git@github.com\/intel-collab\/firmware.bmc.openbmc.applications.memory-resilience-technology-engine.git;protocol=ssh;branch=main/git@git.ami.com\/core\/oe\/advanced-features\/firmware.bmc.openbmc.applications.memory-resilience-technology-engine.git;protocol=ssh;branch=main/g' openbmc-meta-intel/meta-restricted/recipes-core/memory-resilience-technology-engine/memory-resilience-technology-engine.bb

sed -i 's/git@github.com\/intel-collab\/firmware.bmc.openbmc.applications.optane-memory.git;protocol=ssh;branch=main/git@git.ami.com\/core\/oe\/advanced-features\/firmware.bmc.openbmc.applications.optane-memory.git;protocol=ssh;branch=main/g' openbmc-meta-intel/meta-restricted/recipes-intel/optane-memory/optane-memory_git.bb

sed -i 's/git@github.com\/intel-collab\/firmware.bmc.openbmc.applications.mctp-emulator.git;protocol=ssh;branch=main/git@git.ami.com\/core\/oe\/advanced-features\/firmware.bmc.openbmc.applications.mctp-emulator.git;protocol=ssh;branch=main/g' openbmc-meta-intel/meta-common/recipes-phosphor/pmci/mctp-emulator.bb
