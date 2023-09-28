#!/bin/sh

sed -i 's/git@github.com\/intel-bmc\/firmware.bmc.openbmc.applications.mtd-util.git;protocol=ssh;branch=main/git@git.ami.com\/core\/ami-bmc\/one-tree\/core\/firmware.bmc.openbmc.applications.mtd-util.git;protocol=ssh;branch=main/g' openbmc-meta-intel/meta-common/recipes-devtools/mtd-util/mtd-util.bb

sed -i 's/git@github.com\/intel-bmc\/firmware.bmc.openbmc.applications.host-misc-comm-manager;protocol=ssh;branch=main/git@git.ami.com\/core\/ami-bmc\/one-tree\/core\/firmware.bmc.openbmc.applications.host-misc-comm-manager;protocol=ssh;branch=main/g' openbmc-meta-intel/meta-common/recipes-intel/host-misc-comm-manager/host-misc-comm-manager_git.bb

sed -i 's/git@github.com\/intel-bmc\/firmware.bmc.openbmc.applications.intel-pfr-signing-utility.git;protocol=ssh;branch=main/git@git.ami.com\/core\/ami-bmc\/one-tree\/core\/firmware.bmc.openbmc.applications.intel-pfr-signing-utility.git;protocol=ssh;branch=main/g' openbmc-meta-intel/meta-common/recipes-intel/intel-pfr/intel-pfr-signing-utility-native.bb

sed -i 's/git@github.com\/intel-bmc\/firmware.bmc.openbmc.applications.psu-manager.git;protocol=ssh;branch=main/git@git.ami.com\/core\/ami-bmc\/one-tree\/core\/firmware.bmc.openbmc.applications.psu-manager.git;protocol=ssh;branch=main/g' openbmc-meta-intel/meta-common/recipes-intel/psu-manager/psu-manager.bb

sed -i 's/git@github.com\/intel-bmc\/os.linux.kernel.openbmc.linux.git;protocol=ssh;branch=${KBRANCH}/git@git.ami.com\/core\/ami-bmc\/base-tech\/os.linux.kernel.openbmc.linux.git;protocol=ssh;branch=${KBRANCH}/g' openbmc-meta-intel/meta-common/recipes-kernel/linux/linux-aspeed_%.bbappend

sed -i 's/git@github.com\/intel-bmc\/firmware.bmc.openbmc.applications.node-manager-proxy.git;protocol=ssh;branch=main/git@git.ami.com\/core\/ami-bmc\/one-tree\/core\/firmware.bmc.openbmc.applications.node-manager-proxy.git;protocol=ssh;branch=main/g' openbmc-meta-intel/meta-common/recipes-phosphor/ipmi/phosphor-node-manager-proxy_git.bb

sed -i 's/git@github.com\/intel-collab\/firmware.bmc.openbmc.applications.node-manager-proxy.git;protocol=ssh;branch=main/git@git.ami.com\/core\/ami-bmc\/one-tree\/core\/firmware.bmc.openbmc.applications.node-manager-proxy.git;protocol=ssh;branch=main/g' openbmc-meta-intel/meta-common/recipes-phosphor/ipmi/phosphor-node-manager-proxy_git.bb

sed -i 's/git@github.com\/intel-bmc\/firmware.bmc.openbmc.libraries.libmctp.git;protocol=ssh;branch=main/git@git.ami.com\/core\/ami-bmc\/one-tree\/core\/firmware.bmc.openbmc.libraries.libmctp.git;protocol=ssh;branch=main/g' openbmc-meta-intel/meta-common/recipes-phosphor/pmci/libmctp-intel_git.bb

sed -i 's/git@github.com\/intel-bmc\/firmware.bmc.openbmc.libraries.libpldm.git;protocol=ssh;branch=main/git@git.ami.com\/core\/ami-bmc\/one-tree\/core\/firmware.bmc.openbmc.libraries.libpldm.git;protocol=ssh;branch=main/g' openbmc-meta-intel/meta-common/recipes-phosphor/pmci/libpldm-intel_git.bb

sed -i 's/git@github.com\/intel-bmc\/firmware.bmc.openbmc.libraries.mctp-wrapper.git;protocol=ssh;branch=main/git@git.ami.com\/core\/ami-bmc\/one-tree\/core\/firmware.bmc.openbmc.libraries.mctp-wrapper.git;protocol=ssh;branch=main/g' openbmc-meta-intel/meta-common/recipes-phosphor/pmci/mctp-wrapper.bb

sed -i 's/git@github.com\/intel-bmc\/firmware.bmc.openbmc.applications.mctpd.git;protocol=ssh;branch=main/git@git.ami.com\/core\/ami-bmc\/one-tree\/core\/firmware.bmc.openbmc.applications.mctpd.git;protocol=ssh;branch=main/g' openbmc-meta-intel/meta-common/recipes-phosphor/pmci/mctpd.bb

sed -i 's/git@github.com\/intel-bmc\/firmware.bmc.openbmc.libraries.mctpwplus.git;protocol=ssh;branch=main/git@git.ami.com\/core\/ami-bmc\/one-tree\/core\/firmware.bmc.openbmc.libraries.mctpwplus.git;protocol=ssh;branch=main/g' openbmc-meta-intel/meta-common/recipes-phosphor/pmci/mctpwplus.bb

sed -i 's/git@github.com\/intel-bmc\/firmware.bmc.openbmc.applications.nvme-mi-daemon.git;protocol=ssh;branch=main/git@git.ami.com\/core\/ami-bmc\/one-tree\/core\/firmware.bmc.openbmc.applications.nvme-mi-daemon.git;protocol=ssh;branch=main/g' openbmc-meta-intel/meta-common/recipes-phosphor/pmci/nvmemi-daemon.bb

sed -i 's/git@github.com\/intel-bmc\/firmware.bmc.openbmc.applications.pldmd.git;protocol=ssh;branch=main/git@git.ami.com\/core\/ami-bmc\/one-tree\/core\/firmware.bmc.openbmc.applications.pldmd.git;protocol=ssh;branch=main/g' openbmc-meta-intel/meta-common/recipes-phosphor/pmci/pldmd.bb

sed -i 's/git@github.com\/intel-bmc\/firmware.bmc.openbmc.applications.pmci-launcher.git;protocol=ssh;branch=main/git@git.ami.com\/core\/ami-bmc\/one-tree\/core\/firmware.bmc.openbmc.applications.pmci-launcher.git;protocol=ssh;branch=main/g' openbmc-meta-intel/meta-common/recipes-phosphor/pmci/pmci-launcher.bb

sed -i 's/git@github.com\/intel-bmc\/firmware.bmc.openbmc.applications.provisioning-mode-manager.git;protocol=ssh;branch=main/git@git.ami.com\/core\/ami-bmc\/one-tree\/core\/firmware.bmc.openbmc.applications.provisioning-mode-manager.git;protocol=ssh;branch=main/g' openbmc-meta-intel/meta-common/recipes-phosphor/prov-mode-mgr/prov-mode-mgr_git.bb

sed -i 's/git@github.com\/intel-bmc\/firmware.bmc.openbmc.applications.security-manager.git;protocol=ssh;branch=main/git@git.ami.com\/core\/ami-bmc\/one-tree\/core\/firmware.bmc.openbmc.applications.security-manager.git;protocol=ssh;branch=main/g' openbmc-meta-intel/meta-common/recipes-phosphor/security-manager/security-manager_git.bb

sed -i 's/git@github.com\/intel-bmc\/firmware.bmc.openbmc.applications.settings-manager.git;protocol=ssh;branch=main/git@git.ami.com\/core\/ami-bmc\/one-tree\/core\/firmware.bmc.openbmc.applications.settings-manager.git;protocol=ssh;branch=main/g' openbmc-meta-intel/meta-common/recipes-phosphor/settings/settings_git.bb

sed -i 's/git@github.com\/intel-bmc\/firmware.bmc.openbmc.applications.special-mode-manager.git;protocol=ssh;branch=main/git@git.ami.com\/core\/ami-bmc\/one-tree\/core\/firmware.bmc.openbmc.applications.special-mode-manager.git;protocol=ssh;branch=main/g' openbmc-meta-intel/meta-common/recipes-phosphor/special-mode-mgr/special-mode-mgr_git.bb

sed -i 's/git@github.com\/intel-bmc\/firmware.bmc.openbmc.applications.virtual-media.git;protocol=ssh;branch=main/git@git.ami.com\/core\/ami-bmc\/one-tree\/core\/firmware.bmc.openbmc.applications.virtual-media.git;protocol=ssh;branch=main/g' openbmc-meta-intel/meta-common/recipes-phosphor/virtual-media/virtual-media.bb

sed -i 's/git@github.com\/intel-bmc\/firmware.bmc.openbmc.applications.mctp-emulator.git;protocol=ssh;branch=main/git@git.ami.com\/core\/ami-bmc\/one-tree\/core\/firmware.bmc.openbmc.applications.mctp-emulator.git;protocol=ssh;branch=main/g' openbmc-meta-intel/meta-common/recipes-phosphor/pmci/mctp-emulator.bb

sed -i 's/git@github.com\/intel-collab\/firmware.bmc.openbmc.applications.mctp-emulator.git;protocol=ssh;branch=main/git@git.ami.com\/core\/ami-bmc\/one-tree\/core\/firmware.bmc.openbmc.applications.mctp-emulator.git;protocol=ssh;branch=main/g' openbmc-meta-intel/meta-common/recipes-phosphor/pmci/mctp-emulator.bb

sed -i 's/git@github.com\/intel-bmc\/firmware.bmc.openbmc.applications.secure-control-module-i2c-memory-map.git;protocol=ssh;branch=main/git@git.ami.com\/core\/ami-bmc\/one-tree\/core\/firmware.bmc.openbmc.applications.secure-control-module-i2c-memory-map.git;protocol=ssh;branch=main/g' openbmc-meta-intel/meta-common/recipes-intel/scm-i2c-memory-map/scm-i2c-memory-map.bb

sed -i 's/git@github.com\/intel-bmc\/firmware.bmc.openbmc.applications.domain-mapperd.git;protocol=ssh;branch=main/git@git.ami.com\/core\/ami-bmc\/one-tree\/core\/firmware.bmc.openbmc.applications.domain-mapperd.git;protocol=ssh;branch=main/g' openbmc-meta-intel/meta-common/recipes-intel/domain-mapperd/domain-mapperd.bb

sed -i 's/git@github.com\/intel-bmc\/firmware.bmc.openbmc.libraries.libespi.git;protocol=ssh;branch=main/git@git.ami.com\/core\/ami-bmc\/one-tree\/core\/firmware.bmc.openbmc.libraries.libespi.git;protocol=ssh;branch=main/g' openbmc-meta-intel/meta-common/recipes-core/libespi/libespi_git.bb

sed -i 's/git@github.com\/intel-bmc\/firmware.bmc.openbmc.libraries.libpmt.git;protocol=ssh;branch=main/git@git.ami.com\/core\/ami-bmc\/one-tree\/core\/firmware.bmc.openbmc.libraries.libpmt.git;protocol=ssh;branch=main/g' openbmc-meta-intel/meta-common/recipes-intel/pmt/libpmt_git.bb

sed -i 's/git@github.com\/intel-bmc\/firmware.bmc.openbmc.applications.power-feature-discovery.git;protocol=ssh;branch=main/git@git.ami.com\/core\/ami-bmc\/one-tree\/core\/firmware.bmc.openbmc.applications.power-feature-discovery.git;protocol=ssh;branch=main/g' openbmc-meta-intel/meta-common/recipes-intel/power-feature-discovery/power-feature-discovery_git.bb

sed -i 's/git@github.com\/intel-bmc\/firmware.bmc.openbmc.applications.memory-resilience-technology.git;protocol=ssh;branch=main/git@git.ami.com\/core\/ami-bmc\/one-tree\/intel\/firmware.bmc.openbmc.applications.memory-resilience-technology.git;protocol=ssh;branch=main/g' openbmc-meta-intel/meta-restricted/recipes-intel/mrt/memory-resilience-technology-engine.bb

sed -i 's/git@github.com\/intel-bmc\/firmware.bmc.openbmc.applications.memory-resilience-technology.git;protocol=ssh;branch=main/git@git.ami.com\/core\/ami-bmc\/one-tree\/intel\/firmware.bmc.openbmc.applications.memory-resilience-technology.git;protocol=ssh;branch=main/g' openbmc-meta-intel/meta-restricted/recipes-intel/mrt/memory-error-collector.bb

sed -i 's/git@github.com\/intel-bmc\/firmware.bmc.openbmc.applications.host-memory.git;protocol=ssh;branch=main/git@git.ami.com\/core\/ami-bmc\/one-tree\/intel\/firmware.bmc.openbmc.applications.host-memory.git;protocol=ssh;branch=main/g' openbmc-meta-intel/meta-restricted/recipes-intel/telemetry/host-memory_git.bb

sed -i 's/git@github.com\/intel-bmc\/firmware.bmc.openbmc.applications.optane-memory.git;protocol=ssh;branch=main/git@git.ami.com\/core\/ami-bmc\/one-tree\/intel\/firmware.bmc.openbmc.applications.optane-memory.git;protocol=ssh;branch=main/g' openbmc-meta-intel/meta-restricted/recipes-intel/optane-memory/optane-memory_git.bb

sed -i 's/git@github.com\/intel-bmc\/firmware.bmc.openbmc.applications.bmc-assisted-fru-isolation.git;branch=main;protocol=ssh/git@git.ami.com\/core\/ami-bmc\/one-tree\/intel\/firmware.bmc.openbmc.applications.bmc-assisted-fru-isolation.git;branch=main;protocol=ssh/g' openbmc-meta-intel/meta-restricted/recipes-intel/acd/bafi.bb

sed -i 's/git@github.com\/intel-bmc\/firmware.bmc.openbmc.applications.spdmd.git;protocol=ssh;branch=main/git@git.ami.com\/core\/ami-bmc\/one-tree\/intel\/firmware.bmc.openbmc.applications.spdmd.git;protocol=ssh;branch=main/g' openbmc-meta-intel/meta-restricted/recipes-intel/fw-security/spdmd.bb

sed -i 's/git@github.com\/intel-bmc\/firmware.bmc.openbmc.libraries.spdmapplib.git;protocol=ssh;branch=main/git@git.ami.com\/core\/ami-bmc\/one-tree\/intel\/firmware.bmc.openbmc.libraries.spdmapplib.git;protocol=ssh;branch=main/g' openbmc-meta-intel/meta-restricted/recipes-intel/fw-security/spdmapplib.bb

sed -i 's/git@github.com\/intel-bmc\/firmware.bmc.openbmc.applications.ras-manager.git;protocol=ssh;branch=main/git@git.ami.com\/core\/ami-bmc\/one-tree\/intel\/firmware.bmc.openbmc.applications.ras-manager.git;protocol=ssh;branch=main/g' openbmc-meta-intel/meta-restricted/recipes-intel/ras-offload/ras-manager_git.bb

sed -i 's/git@github.com\/intel-bmc\/firmware.bmc.openbmc.applications.crashdump.git;branch=main;protocol=ssh/git@git.ami.com\/core\/ami-bmc\/one-tree\/intel\/firmware.bmc.openbmc.applications.crashdump.git;branch=main;protocol=ssh/g' openbmc-meta-intel/meta-restricted/recipes-intel/acd/crashdump_git.bb

sed -i 's/git@github.com\/intel-bmc\/firmware.bmc.openbmc.applications.at-scale-debug.git;protocol=ssh;branch=main/git@git.ami.com\/core\/ami-bmc\/one-tree\/intel\/firmware.bmc.openbmc.applications.at-scale-debug.git;protocol=ssh;branch=main/g' openbmc-meta-intel/meta-common/recipes-core/at-scale-debug/at-scale-debug_git.bb

sed -i 's/git@github.com\/intel-bmc\/firmware.bmc.openbmc.applications.crashdump-add-in-card.git;protocol=ssh;branch=main/git@git.ami.com\/core\/ami-bmc\/one-tree\/intel\/firmware.bmc.openbmc.applications.crashdump-add-in-card.git;protocol=ssh;branch=main/g' openbmc-meta-intel/meta-restricted/recipes-intel/aic-crashdump/aic-crashdump.bb

sed -i 's/git@github.com\/intel-bmc\/firmware.bmc.openbmc.applications.node-manager.git;protocol=ssh;branch=main/git@git.ami.com\/core\/ami-bmc\/one-tree\/intel\/firmware.bmc.openbmc.applications.node-manager.git;protocol=ssh;branch=main/g' openbmc-meta-intel/meta-restricted/recipes-intel/nm/node-manager_git.bb

sed -i 's/git@github.com\/intel-bmc\/firmware.bmc.openbmc.applications.bmc-collector.git;protocol=ssh;branch=main/git@git.ami.com\/core\/ami-bmc\/one-tree\/intel\/firmware.bmc.openbmc.applications.bmc-collector.git;protocol=ssh;branch=main/g' openbmc-meta-intel/meta-restricted/recipes-intel/acd/bmc-collector_git.bb

sed -i 's/git@github.com\/intel-bmc\/firmware.bmc.openbmc.applications.cups-service.git;protocol=ssh;branch=main/git@git.ami.com\/core\/ami-bmc\/one-tree\/intel\/firmware.bmc.openbmc.applications.cups-service.git;protocol=ssh;branch=main/g' openbmc-meta-intel/meta-restricted/recipes-intel/telemetry/cups-service.bb

sed -i 's/git@github.com\/intel-bmc\/firmware.bmc.openbmc.applications.cups-service.git;protocol=ssh;branch=egs/git@git.ami.com\/core\/ami-bmc\/one-tree\/intel\/firmware.bmc.openbmc.applications.cups-service.git;protocol=ssh;branch=egs/g' openbmc-meta-intel/meta-restricted/recipes-intel/telemetry/cups-service.bb

sed -i 's/git@github.com\/intel-bmc\/firmware.bmc.openbmc.applications.cups-service.git;protocol=ssh;branch=main/git@git.ami.com\/core\/ami-bmc\/one-tree\/intel\/firmware.bmc.openbmc.applications.cups-service.git;protocol=ssh;branch=main/g' openbmc-meta-intel/meta-restricted/recipes-intel/telemetry/cups-ut-native.bb

sed -i 's/git@github.com\/intel-bmc\/firmware.bmc.openbmc.applications.cups-service.git;protocol=ssh;branch=egs/git@git.ami.com\/core\/ami-bmc\/one-tree\/intel\/firmware.bmc.openbmc.applications.cups-service.git;protocol=ssh;branch=egs/g' openbmc-meta-intel/meta-restricted/recipes-intel/telemetry/cups-ut-native.bb

sed -i 's/git@github.com\/intel-bmc\/firmware.bmc.openbmc.applications.platform-monitoring-technology.git;protocol=ssh;branch=main/git@git.ami.com\/core\/ami-bmc\/one-tree\/intel\/firmware.bmc.openbmc.applications.platform-monitoring-technology.git;protocol=ssh;branch=main/g' openbmc-meta-intel/meta-restricted/recipes-intel/telemetry/pmt_git.bb

sed -i 's/git@github.com\/intel-bmc\/firmware.bmc.openbmc.applications.mmbi-seamless.git;protocol=ssh;branch=main/git@git.ami.com\/core\/ami-bmc\/one-tree\/intel\/firmware.bmc.openbmc.applications.mmbi-seamless.git;protocol=ssh;branch=main/g' openbmc-meta-intel/meta-restricted/recipes-intel/seamless/mmbi-seamless.bb

sed -i 's/git@github.com\/intel-bmc\/firmware.bmc.openbmc.applications.trusted-application.git;protocol=ssh;nobranch=1/git@git.ami.com\/core\/ami-bmc\/one-tree\/intel\/firmware.bmc.openbmc.applications.trusted-application.git;protocol=ssh;nobranch=1/g' openbmc-meta-intel/meta-restricted/recipes-optee/optee-user-ta/optee-user-ta_git.bb

sed -i 's/git@github.com\/intel-bmc\/firmware.bmc.openbmc.applications.ondemand.git;protocol=ssh;branch=main/git@git.ami.com\/core\/ami-bmc\/one-tree\/intel\/firmware.bmc.openbmc.applications.ondemand.git;protocol=ssh;branch=main/g' openbmc-meta-intel/meta-restricted/recipes-intel/oob-config/ondemand_git.bb

sed -i 's/git@github.com\/intel-bmc\/firmware.bmc.openbmc.applications.dimm-devices-accessor.git;protocol=ssh;branch=main/git@git.ami.com\/core\/ami-bmc\/one-tree\/core\/firmware.bmc.openbmc.applications.dimm-devices-accessor.git;protocol=ssh;branch=main/g' openbmc-meta-intel/meta-common/recipes-intel/dimm-devices-accessor/dimm-devices-accessor.bb

