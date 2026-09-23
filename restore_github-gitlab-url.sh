#!/bin/sh

	sed -i 's/git@github.com\/ocp-hm-openbmc-opf-ami\/phosphor-networkd;protocol=https;branch=main;name=override/git.ami.com\/core\/ami-bmc\/one-tree\/core\/phosphor-networkd;branch=main;protocol=https;name=override/g' meta-ami/meta-common/recipes-network/network/phosphor-network_%.bbappend

	sed -i 's/git@github.com\/ocp-hm-openbmc-opf-ami\/obmc-ikvm;protocol=https;branch=main/git.ami.com\/core\/ami-bmc\/one-tree\/core\/obmc-ikvm;branch=main;protocol=https/g' meta-ami/meta-common/recipes-graphics/obmc-ikvm/obmc-ikvm_%.bbappend

	sed -i 's/github.com\/ocp-hm-openbmc-opf-ami\/x86-power-control.git;protocol=https;branch=master;name=override/git.ami.com\/core\/ami-bmc\/one-tree\/core\/x86-power-control.git;branch=master;protocol=https;name=override/g' meta-ami/meta-common/recipes-x86/chassis/x86-power-control_%.bbappend

	sed -i 's/git@github.com\/ocp-hm-openbmc-opf-ami\/phosphor-debug-collector.git;branch=master;protocol=https;name=override/git.ami.com\/core\/ami-bmc\/one-tree\/core\/phosphor-debug-collector.git;branch=master;protocol=https;name=override/g' meta-ami/meta-common/recipes-phosphor/dump/phosphor-debug-collector_%.bbappend

	sed -i 's/git@github.com\/ocp-hm-openbmc-opf-ami\/intel-ipmi-oem-ext.git;branch=master;protocol=https;name=override/git.ami.com\/core\/ami-bmc\/one-tree\/core\/intel-ipmi-oem-ext.git;branch=master;protocol=https;name=override/g' meta-ami/meta-common/recipes-phosphor/ipmi/intel-ipmi-oem-ext.bbappend

	sed -i 's/git@github.com\/ocp-hm-openbmc-opf-ami\/intel-ipmi-oem;protocol=https;branch=master;name=override/git.ami.com\/core\/ami-bmc\/one-tree\/core\/intel-ipmi-oem.git;branch=master;protocol=https;name=override/g' meta-ami/meta-common/recipes-phosphor/ipmi/intel-ipmi-oem_%.bbappend

	sed -i 's/git@github.com\/ocp-hm-openbmc-opf-ami\/phosphor-host-ipmid;protocol=https;branch=master;name=override/git.ami.com\/core\/ami-bmc\/one-tree\/core\/phosphor-host-ipmid.git;branch=master;protocol=https;name=override/g' meta-ami/meta-common/recipes-phosphor/ipmi/phosphor-ipmi-host_%.bbappend

	sed -i 's/git@github.com\/ocp-hm-openbmc-opf-ami\/phosphor-logging.git;branch=master;protocol=https;name=override/git.ami.com\/core\/ami-bmc\/one-tree\/core\/phosphor-logging.git;branch=master;protocol=https;name=override/g' meta-ami/meta-common/recipes-phosphor/logging/phosphor-logging_%.bbappend

	sed -i 's/git@github.com\/ocp-hm-openbmc-opf-ami\/phosphor-sel-logger.git;branch=master;protocol=https;name=override/git.ami.com\/core\/ami-bmc\/one-tree\/core\/phosphor-sel-logger.git;branch=master;protocol=https;name=override/g' meta-ami/meta-common/recipes-phosphor/sel-logger/phosphor-sel-logger_%.bbappend

	sed -i 's/git@github.com\/ocp-hm-openbmc-opf-ami\/webui-vue;protocol=https;branch=main/git.ami.com\/core\/ami-bmc\/one-tree\/core\/webui-vue.git;branch=main;protocol=https;name=webui/g' meta-ami/meta-common/recipes-phosphor/webui/webui-vue_%.bbappend

	sed -i 's/git@github.com\/ocp-hm-openbmc-opf-ami\/phosphor-time-manager.git;branch=master;protocol=https;name=override/git.ami.com\/core\/ami-bmc\/one-tree\/core\/phosphor-time-manager.git;branch=master;protocol=https;name=override/g' meta-ami/meta-common/recipes-phosphor/date-time/phosphor-time-manager_%.bbappend

	sed -i 's/git@github.com\/ocp-hm-openbmc-opf-ami\/snmp-agent;protocol=https;branch=main/git.ami.com\/core\/ami-bmc\/one-tree\/core\/snmp-agent.git;branch=main;protocol=https/g' meta-ami/meta-common/recipes-phosphor/snmp/snmp-agent_%.bb

	sed -i 's/git@github.com\/ocp-hm-openbmc-opf-ami\/session-manager.git;protocol=https;branch=main/git.ami.com\/core\/ami-bmc\/one-tree\/core\/session-manager.git;protocol=https;branch=main/g' meta-ami/meta-common/recipes-phosphor/session-management/session-management_git.bb

	sed -i 's/git@github.com\/ocp-hm-openbmc-opf-ami\/phosphor-gpio-monitor.git;branch=master;protocol=https;name=override/git.ami.com\/core\/ami-bmc\/one-tree\/core\/phosphor-gpio-monitor.git;branch=master;protocol=https;name=override/g' meta-ami/meta-common/recipes-phosphor/gpio/phosphor-gpio-monitor_%.bbappend

	sed -i 's/git@github.com\/ocp-hm-openbmc-opf-ami\/phosphor-dbus-interfaces;protocol=https;branch=main;name=override/git.ami.com\/core\/ami-bmc\/one-tree\/core\/phosphor-dbus-interfaces.git;branch=main;protocol=https;name=override/g' meta-ami/meta-common/recipes-phosphor/dbus/phosphor-dbus-interfaces_%.bbappend

	sed -i 's/git@github.com\/ocp-hm-openbmc-opf-ami\/obmc-console.git;branch=master;protocol=https;name=override/git.ami.com\/core\/ami-bmc\/one-tree\/core\/obmc-console.git;branch=master;protocol=https;name=override/g' meta-ami/meta-common/recipes-phosphor/console/obmc-console_%.bbappend

	sed -i 's/git@github.com\/ocp-hm-openbmc-opf-ami\/bmcweb;protocol=https;branch=master;name=override/git.ami.com\/core\/ami-bmc\/one-tree\/core\/bmcweb;branch=master;protocol=https;name=override/g' meta-ami/meta-common/recipes-phosphor/bmcweb/bmcweb_%.bbappend

	sed -i 's/git@github.com\/ocp-hm-openbmc-opf-ami\/phosphor-watchdog.git;branch=master;protocol=https;name=override/git.ami.com\/core\/ami-bmc\/one-tree\/core\/phosphor-watchdog.git;branch=master;protocol=https;name=override/g' meta-ami/meta-common/recipes-phosphor/watchdog/phosphor-watchdog_%.bbappend

	sed -i 's/git@github.com\/ocp-hm-openbmc-opf-ami\/phosphor-post-code-manager.git;branch=master;protocol=https;name=override/git.ami.com\/core\/ami-bmc\/one-tree\/core\/phosphor-post-code-manager.git;branch=master;protocol=https;name=override/g' meta-ami/meta-common/recipes-phosphor/state/phosphor-post-code-manager_%.bbappend

	sed -i 's/git@github.com\/ocp-hm-openbmc-opf-ami\/phosphor-pid-control.git;branch=master;protocol=https;name=override/git.ami.com\/core\/ami-bmc\/one-tree\/core\/phosphor-pid-control.git;branch=master;protocol=https;name=override/g' meta-ami/meta-common/recipes-phosphor/fans/phosphor-pid-control_%.bbappend

	sed -i 's/git@github.com\/ocp-hm-openbmc-opf-ami\/telemetry.git;branch=master;protocol=https;name=override/git.ami.com\/core\/ami-bmc\/one-tree\/core\/telemetry.git;branch=master;protocol=https;name=override/g' meta-ami/meta-common/recipes-phosphor/telemetry/telemetry_%.bbappend

	sed -i 's/git@github.com\/ocp-hm-openbmc-opf-ami\/phosphor-health-monitor.git;branch=master;protocol=https;name=override/git.ami.com\/core\/ami-bmc\/one-tree\/core\/phosphor-health-monitor.git;branch=master;protocol=https;name=override/g' meta-ami/meta-common/recipes-phosphor/health/phosphor-health-monitor_%.bbappend

	sed -i 's/git@github.com\/ocp-hm-openbmc-opf-ami\/entity-manager.git;branch=master;protocol=https;name=override/git.ami.com\/core\/ami-bmc\/one-tree\/core\/entity-manager.git;branch=master;protocol=https;name=override/g' meta-ami/meta-common/recipes-phosphor/configuration/entity-manager_%.bbappend

	sed -i 's/git@github.com\/ocp-hm-openbmc-opf-ami\/dbus-sensors;protocol=https;branch=master;name=override/git.ami.com\/core\/ami-bmc\/one-tree\/core\/dbus-sensors.git;branch=master;protocol=https;name=override/g' meta-ami/meta-common/recipes-phosphor/sensors/dbus-sensors_%.bbappend

	sed -i 's/git@github.com\/ocp-hm-openbmc-opf-ami\/libapisensor.git;protocol=https;branch=main/git.ami.com\/core\/ami-bmc\/one-tree\/core\/libapisensor.git;protocol=https;branch=main/g' meta-ami/meta-common/recipes-phosphor/sensors/libapisensor_git.bb

	sed -i 's/git@github.com\/ocp-hm-openbmc-opf-ami\/sensor-history-reader.git;protocol=https;branch=master/git.ami.com\/core\/ami-bmc\/one-tree\/core\/sensor-history-reader.git;protocol=https;branch=master/g' meta-ami/meta-common/recipes-ami/sensor-reader/sensor-reader_git.bb

	sed -i 's/git@github.com\/ocp-hm-openbmc-opf-ami\/two-factor-authentication.git;protocol=https;branch=main/git.ami.com\/core\/ami-bmc\/one-tree\/core\/two-factor-authentication.git;protocol=https;branch=main/g' meta-ami/meta-common/recipes-ami/two-factor-authentication/web-two-factor-authentication.bb

	sed -i 's/git@github.com\/ocp-hm-openbmc-opf-ami\/platform-event-filter.git;protocol=https;branch=main/git.ami.com\/core\/ami-bmc\/one-tree\/core\/platform-event-filter.git;protocol=https;branch=main/g' meta-ami/meta-common/recipes-ami/pef/pef-alert-manager.bb

	sed -i 's/git@github.com\/ocp-hm-openbmc-opf-ami\/email-alert-manager.git;protocol=https;branch=main/git.ami.com\/core\/ami-bmc\/one-tree\/core\/email-alert-manager.git;protocol=https;branch=main/g' meta-ami/meta-common/recipes-ami/pef/mail-alert-manager.bb

	sed -i 's/git@github.com\/ocp-hm-openbmc-opf-ami\/obmc-ikvm;protocol=https;branch=main/git.ami.com\/core\/ami-bmc\/one-tree\/core\/obmc-ikvm;protocol=https;branch=main/g' meta-ami/meta-common/recipes-ami/kvm-dbus-monitor/kvm-dbus-monitor_git.bb

	sed -i 's/git@github.com\/ocp-hm-openbmc-opf-ami\/libpdkhook.git;protocol=https;branch=main/git.ami.com\/core\/ami-bmc\/one-tree\/core\/libpdkhook.git;protocol=https;branch=main/g' meta-ami/meta-common/recipes-ami/libpdkhook/libpdkhook_git.bb

	sed -i 's|git@github.com/ocp-hm-openbmc-opf-ami/linux.git|git\.ami\.com/core/ami-bmc/base-tech/linux-lf\.git|g' meta-ami/meta-common/recipes-kernel/linux/linux-onetree.bb

	sed -i 's/git@github.com\/ocp-hm-openbmc-opf-ami\/libmctp.git;protocol=https;branch=main/git.ami.com\/core\/ami-bmc\/one-tree\/core\/libmctp.git;protocol=https;branch=main/g' meta-ami/meta-common/recipes-phosphor/libmctp/libmctp_%.bbappend

	sed -i 's/github.com\/ocp-hm-openbmc-opf-ami\/host-error-monitor;branch=master;protocol=https;name=override/git.ami.com\/core\/ami-bmc\/one-tree\/core\/host-error-monitor.git;branch=master;protocol=https;name=override/g' meta-ami/meta-common/recipes-core/host-error-monitor/host-error-monitor_%.bbappend

	sed -i 's/github.com\/ocp-hm-openbmc-opf-ami\/mctp-ext.git;protocol=https;branch=main/git.ami.com\/core\/ami-bmc\/one-tree\/core\/mctp-ext.git;protocol=https;branch=main/g' meta-ami/meta-common/recipes-networking/mctp-ext/mctp-ext_git.bb

	sed -i 's/git@github.com\/ocp-hm-openbmc-opf-ami\/mctp-oem.git;protocol=https;branch=main/git.ami.com\/core\/ami-bmc\/one-tree\/core\/mctp-oem.git;protocol=https;branch=main/g' meta-ami/meta-common/recipes-networking/mctp-oem/mctp-oem_git.bb

	sed -i 's/github.com\/ocp-hm-openbmc-opf-ami\/mctp.git;protocol=https;branch=main/git.ami.com\/core\/ami-bmc\/one-tree\/core\/mctp.git;protocol=https;branch=main/g' meta-ami/meta-common/recipes-networking/mctp/mctp_%.bbappend

	sed -i 's/git@github.com\/ocp-hm-openbmc-opf-ami\/phosphor-net-ipmid.git;branch=master;protocol=https;name=override/git.ami.com\/core\/ami-bmc\/one-tree\/core\/phosphor-net-ipmid.git;branch=master;protocol=https;name=override/g' meta-ami/meta-common/recipes-phosphor/ipmi/phosphor-ipmi-net_%.bbappend

	sed -i 's/git@github.com\/ocp-hm-openbmc-opf-ami\/service-config-manager.git;branch=master;protocol=https;name=override/git.ami.com\/core\/ami-bmc\/one-tree\/core\/service-config-manager.git;branch=master;protocol=https;name=override/g' meta-ami/meta-common/recipes-phosphor/srvcfg-manager/srvcfg-manager_git.bbappend

	sed -i 's/github.com\/ocp-hm-openbmc-opf-ami\/webui-libraries.git;branch=main;protocol=https;destsuffix=webui-libs;name=webuilib/git.ami.com\/core\/ami-bmc\/one-tree\/core\/webui-libraries.git;branch=main;protocol=https;destsuffix=webui-libs;name=webuilib/g' meta-ami/meta-common/recipes-phosphor/webui/webui-vue_%.bbappend

	sed -i 's/git@github.com\/ocp-hm-openbmc-opf-ami\/firmware.bmc.openbmc.applications.mctpd.git;protocol=https;branch=openbmc\/release\/birchstream\/common/git.ami.com\/core\/ami-bmc\/one-tree\/core\/firmware.bmc.openbmc.applications.mctpd.git;protocol=https;branch=openbmc\/release\/birchstream\/common/g' meta-ami/meta-common/recipes-phosphor/pmci/mctpd.bbappend

	sed -i 's/git@github.com\/ocp-hm-openbmc-opf-ami\/virtual-media.git;protocol=https;branch=main/git.ami.com\/core\/ami-bmc\/one-tree\/core\/firmware.bmc.openbmc.applications.virtual-media;branch=main;protocol=https/g' meta-ami/meta-common/recipes-phosphor/virtual-media/virtual-media.bbappend

if [ -d "meta-core/meta-common" ]; then

	sed -i 's/git@github.com\/ocp-hm-openbmc-opf-ami\/host-misc-comm-manager.git;protocol=https;branch=main/git@github.com\/intel-bmc\/firmware.bmc.openbmc.applications.host-misc-comm-manager;protocol=ssh;branch=main/g' meta-core/meta-common/recipes-intel/host-misc-comm-manager/host-misc-comm-manager_git.bb

	sed -i 's/git@github.com\/ocp-hm-openbmc-opf-ami\/psu-manager.git;protocol=https;branch=main/git@github.com\/intel-bmc\/firmware.bmc.openbmc.applications.psu-manager.git;protocol=ssh;branch=main/g' meta-core/meta-common/recipes-intel/psu-manager/psu-manager.bb

	sed -i 's/git@github.com\/ocp-hm-openbmc-opf-ami\/node-manager-proxy.git;protocol=https;branch=main/git@github.com\/intel-collab\/firmware.bmc.openbmc.applications.node-manager-proxy.git;protocol=ssh;branch=main/g' meta-core/meta-common/recipes-phosphor/ipmi/phosphor-node-manager-proxy_git.bb

	sed -i 's/git.ami.com\/core\/ami-bmc\/one-tree\/core\/firmware.bmc.openbmc.libraries.libmctp.git;protocol=https;branch=main/git@github.com\/intel-bmc\/firmware.bmc.openbmc.libraries.libmctp.git;protocol=ssh;branch=main/g' meta-core/meta-common/recipes-phosphor/pmci/libmctp-intel_git.bb

	sed -i 's/git.ami.com\/core\/ami-bmc\/one-tree\/core\/firmware.bmc.openbmc.libraries.libpldm.git;protocol=https;branch=main/git@github.com\/intel-bmc\/firmware.bmc.openbmc.libraries.libpldm.git;protocol=ssh;branch=main/g' meta-core/meta-common/recipes-phosphor/pmci/libpldm-intel_git.bb

	sed -i 's/git@github.com\/ocp-hm-openbmc-opf-ami\/mctp-wrapper.git;protocol=https;branch=main/git@github.com\/intel-bmc\/firmware.bmc.openbmc.libraries.mctp-wrapper.git;protocol=ssh;branch=main/g' meta-core/meta-common/recipes-phosphor/pmci/mctp-wrapper.bb

	sed -i 's/git@github.com\/ocp-hm-openbmc-opf-ami\/mctpd.git;protocol=https;branch=main/git@github.com\/intel-bmc\/firmware.bmc.openbmc.applications.mctpd.git;protocol=ssh;branch=main/g' meta-core/meta-common/recipes-phosphor/pmci/mctpd.bb

	sed -i 's/git@github.com\/ocp-hm-openbmc-opf-ami\/mctpwplus.git;protocol=https;branch=main/git@github.com\/intel-bmc\/firmware.bmc.openbmc.libraries.mctpwplus.git;protocol=ssh;branch=main/g' meta-core/meta-common/recipes-phosphor/pmci/mctpwplus.bb

	sed -i 's/git@github.com\/ocp-hm-openbmc-opf-ami\/nvme-mi-daemon.git;protocol=https;branch=main/git@github.com\/intel-bmc\/firmware.bmc.openbmc.applications.nvme-mi-daemon.git;protocol=ssh;branch=main/g' meta-core/meta-common/recipes-phosphor/pmci/nvmemi-daemon.bb

	sed -i 's/git@github.com\/ocp-hm-openbmc-opf-ami\/pldmd.git;protocol=https;branch=main/git@github.com\/intel-bmc\/firmware.bmc.openbmc.applications.pldmd.git;protocol=ssh;branch=main/g' meta-core/meta-common/recipes-phosphor/pmci/pldmd.bb

	sed -i 's/git@github.com\/ocp-hm-openbmc-opf-ami\/pmci-launcher.git;protocol=https;branch=main/git@github.com\/intel-bmc\/firmware.bmc.openbmc.applications.pmci-launcher.git;protocol=ssh;branch=main/g' meta-core/meta-common/recipes-phosphor/pmci/pmci-launcher.bb

	sed -i 's/git@github.com\/ocp-hm-openbmc-opf-ami\/provisioning-mode-manager.git;protocol=https;branch=main/git@github.com\/intel-bmc\/firmware.bmc.openbmc.applications.provisioning-mode-manager.git;protocol=ssh;branch=main/g' meta-core/meta-common/recipes-phosphor/prov-mode-mgr/prov-mode-mgr_git.bb

	sed -i 's/git@github.com\/ocp-hm-openbmc-opf-ami\/security-manager.git;protocol=https;branch=main/git@github.com\/intel-bmc\/firmware.bmc.openbmc.applications.security-manager.git;protocol=ssh;branch=main/g' meta-core/meta-common/recipes-phosphor/security-manager/security-manager_git.bb

	sed -i 's/git@github.com\/ocp-hm-openbmc-opf-ami\/settings-manager.git;protocol=https;branch=main/git@github.com\/intel-bmc\/firmware.bmc.openbmc.applications.settings-manager.git;protocol=ssh;branch=main/g' meta-core/meta-common/recipes-phosphor/settings/settings_git.bb

	sed -i 's/git@github.com\/ocp-hm-openbmc-opf-ami\/special-mode-manager.git;protocol=https;branch=main/git@github.com\/intel-bmc\/firmware.bmc.openbmc.applications.special-mode-manager.git;protocol=ssh;branch=main/g' meta-core/meta-common/recipes-phosphor/special-mode-mgr/special-mode-mgr_git.bb

	sed -i 's/git@github.com\/ocp-hm-openbmc-opf-ami\/mctp-emulator.git;protocol=https;branch=main/git@github.com\/intel-collab\/firmware.bmc.openbmc.applications.mctp-emulator.git;protocol=ssh;branch=main/g' meta-core/meta-common/recipes-phosphor/pmci/mctp-emulator.bb

	sed -i 's/git.ami.com\/core\/ami-bmc\/one-tree\/intel\/firmware.bmc.openbmc.applications.at-scale-debug.git;protocol=https;branch=main/git@github.com\/intel-bmc\/firmware.bmc.openbmc.applications.at-scale-debug.git;protocol=ssh;branch=main/g' meta-core/meta-common/recipes-core/at-scale-debug/at-scale-debug_git.bb

	sed -i 's/git.ami.com\/core\/ami-bmc\/one-tree\/core\/firmware.bmc.openbmc.libraries.libpeciplus.git;protocol=https;branch=main/git@github.com\/intel-collab\/firmware.bmc.openbmc.libraries.libpeciplus.git;protocol=ssh;branch=main/g' meta-core/meta-common/recipes-core/libpeciplus/libpeciplus_git.bb

	sed -i 's/git.ami.com\/core\/ami-bmc\/one-tree\/core\/firmware.bmc.openbmc.applications.mctp-tools.git;protocol=ssh;branch=main/git@github.com\/intel-collab\/firmware.bmc.openbmc.applications.mctp-tools.git;protocol=ssh;branch=main/g' meta-core/meta-common/recipes-phosphor/pmci/mctp-cmd-tool.bb

	sed -i 's/git.ami.com\/core\/ami-bmc\/one-tree\/core\/firmware.bmc.openbmc.applications.cxl-cci.git;protocol=https;branch=main/git@github.com\/intel-collab\/firmware.bmc.openbmc.applications.cxl-cci.git;protocol=ssh;branch=main/g' meta-core/meta-common/recipes-phosphor/pmci/cxl-cci.bb

	sed -i 's/git@github.com\/ocp-hm-openbmc-opf-ami\/libpeci.git;branch=main;protocol=https/git.ami.com\/core\/ami-bmc\/one-tree\/core\/libpeci.git;branch=main;protocol=https/g' meta-core/meta-common/recipes-core/libpeci/libpeci_%.bbappend

	sed -i 's/git.ami.com\/core\/ami-bmc\/one-tree\/intel\/firmware.bmc.openbmc.applications.i3c-hub-detector.git;protocol=https;branch=oks-main/git@github.com\/ocp-hm-openbmc-opf-ami\/i3c-hub-detector.git;protocol=ssh;branch=oks-main/g' meta-core/meta-common/recipes-phosphor/pmci/i3c-hub-detector.bb

	sed -i 's/git@github.com\/ocp-hm-openbmc-opf-ami\/libpldm.git;protocol=https;branch=main/git@github.com\/intel-bmc\/firmware.bmc.openbmc.libraries.libpldm.git;protocol=ssh;branch=main/g' meta-core/meta-common/recipes-phosphor/pmci/libpldm-intel_git.bb

	sed -i 's/git.ami.com\/core\/ami-bmc\/one-tree\/intel\/firmware.bmc.openbmc.applications.kmctp-setup.git;protocol=https;branch=oks-dev/git@github.com\/ocp-hm-openbmc-opf-ami\/mctp-setup.git;protocol=ssh;branch=oks-dev/g' meta-core/meta-common/recipes-phosphor/pmci/mctp-setup.bb

	sed -i 's/git@github.com\/ocp-hm-openbmc-opf-ami\/virtual-media.git;protocol=https;branch=main/git@github.com\/intel-bmc\/firmware.bmc.openbmc.applications.virtual-media.git;protocol=ssh;branch=main/g' meta-core/meta-common/recipes-phosphor/virtual-media/virtual-media.bb

	sed -i 's/git@github.com\/ocp-hm-openbmc-opf-ami\/mctpd.git;protocol=https;branch=main/git@github.com\/intel-bmc\/firmware.bmc.openbmc.applications.mctpd.git;protocol=ssh;branch=main/g' meta-core/meta-common/recipes-phosphor/pmci/mctpd.bb

else
	echo "INFO : meta-common does not exists."
fi

if [ -d "meta-core/meta-restricted" ]; then

	sed -i 's/git.ami.com\/core\/ami-bmc\/one-tree\/intel\/firmware.bmc.openbmc.applications.host-memory.git;protocol=ssh;branch=main/git@github.com\/intel-bmc\/firmware.bmc.openbmc.applications.host-memory.git;protocol=ssh;branch=main/g' meta-core/meta-restricted/recipes-intel/telemetry/host-memory_git.bb

	sed -i 's/git.ami.com\/core\/ami-bmc\/one-tree\/intel\/firmware.bmc.openbmc.applications.optane-memory.git;protocol=ssh;branch=main/git@github.com\/intel-collab\/firmware.bmc.openbmc.applications.optane-memory.git;protocol=ssh;branch=main/g' meta-core/meta-restricted/recipes-intel/optane-memory/optane-memory_git.bb

	sed -i 's/git.ami.com\/core\/ami-bmc\/one-tree\/intel\/firmware.bmc.openbmc.applications.bmc-assisted-fru-isolation.git;branch=main;protocol=ssh/git@github.com\/intel-bmc\/firmware.bmc.openbmc.applications.bmc-assisted-fru-isolation.git;branch=main;protocol=ssh/g' meta-core/meta-restricted/recipes-intel/acd/bafi.bb

	sed -i 's/git.ami.com\/core\/ami-bmc\/one-tree\/intel\/firmware.bmc.openbmc.libraries.spdmapplib.git;protocol=ssh;branch=main/git@github.com\/intel-bmc\/firmware.bmc.openbmc.libraries.spdmapplib.git;protocol=ssh;branch=main/g' meta-core/meta-common/recipes-intel/spdm/spdmapplib.bb

	sed -i 's/git.ami.com\/core\/ami-bmc\/one-tree\/intel\/firmware.bmc.openbmc.applications.ras-manager.git;protocol=ssh;branch=main/git@github.com\/intel-bmc\/firmware.bmc.openbmc.applications.ras-manager.git;protocol=ssh;branch=main/g' meta-core/meta-restricted/recipes-intel/ras-offload/ras-manager_git.bb

	sed -i 's/git.ami.com\/core\/ami-bmc\/one-tree\/intel\/firmware.bmc.openbmc.applications.crashdump.git;branch=main;protocol=ssh/git@github.com\/intel-bmc\/firmware.bmc.openbmc.applications.crashdump.git;branch=main;protocol=ssh/g' meta-core/meta-restricted/recipes-intel/acd/crashdump_git.bb

	sed -i 's/git.ami.com\/core\/ami-bmc\/one-tree\/intel\/firmware.bmc.openbmc.applications.crashdump-add-in-card.git;protocol=ssh;branch=main/git@github.com\/intel-bmc\/firmware.bmc.openbmc.applications.crashdump-add-in-card.git;protocol=ssh;branch=main/g' meta-core/meta-restricted/recipes-intel/aic-crashdump/aic-crashdump.bb

	sed -i 's/git.ami.com\/core\/ami-bmc\/one-tree\/intel\/firmware.bmc.openbmc.applications.node-manager.git;protocol=ssh;branch=bhs/git@github.com\/intel-bmc\/firmware.bmc.openbmc.applications.node-manager.git;protocol=ssh;branch=bhs/g' meta-core/meta-restricted/recipes-intel/nm/node-manager_git.bb

	sed -i 's/git.ami.com\/core\/ami-bmc\/one-tree\/intel\/firmware.bmc.openbmc.applications.node-manager.git;protocol=ssh;branch=main/git@github.com\/intel-bmc\/firmware.bmc.openbmc.applications.node-manager.git;protocol=ssh;branch=main/g' meta-core/meta-restricted/recipes-intel/nm/node-manager_git.bb

	sed -i 's/git.ami.com\/core\/ami-bmc\/one-tree\/intel\/firmware.bmc.openbmc.applications.bmc-collector.git;protocol=ssh;branch=main/git@github.com\/intel-bmc\/firmware.bmc.openbmc.applications.bmc-collector.git;protocol=ssh;branch=main/g' meta-core/meta-restricted/recipes-intel/acd/bmc-collector_git.bb

	sed -i 's/git.ami.com\/core\/ami-bmc\/one-tree\/intel\/firmware.bmc.openbmc.applications.cups-service.git;protocol=ssh;branch=main/git@github.com\/intel-bmc\/firmware.bmc.openbmc.applications.cups-service.git;protocol=ssh;branch=main/g' meta-core/meta-restricted/recipes-intel/telemetry/cups-service.bb

	sed -i 's/git.ami.com\/core\/ami-bmc\/one-tree\/intel\/firmware.bmc.openbmc.applications.cups-service.git;protocol=ssh;branch=egs/git@github.com\/intel-bmc\/firmware.bmc.openbmc.applications.cups-service.git;protocol=ssh;branch=egs/g' meta-core/meta-restricted/recipes-intel/telemetry/cups-service.bb

	sed -i 's/git.ami.com\/core\/ami-bmc\/one-tree\/intel\/firmware.bmc.openbmc.applications.cups-service.git;protocol=ssh;branch=main/git@github.com\/intel-bmc\/firmware.bmc.openbmc.applications.cups-service.git;protocol=ssh;branch=main/g' meta-core/meta-restricted/recipes-intel/telemetry/cups-ut-native.bb

	sed -i 's/git.ami.com\/core\/ami-bmc\/one-tree\/intel\/firmware.bmc.openbmc.applications.cups-service.git;protocol=ssh;branch=egs/git@github.com\/intel-bmc\/firmware.bmc.openbmc.applications.cups-service.git;protocol=ssh;branch=egs/g' meta-core/meta-restricted/recipes-intel/telemetry/cups-ut-native.bb

	sed -i 's/git.ami.com\/core\/ami-bmc\/one-tree\/intel\/firmware.bmc.openbmc.applications.platform-monitoring-technology.git;protocol=ssh;branch=main/git@github.com\/intel-bmc\/firmware.bmc.openbmc.applications.platform-monitoring-technology.git;protocol=ssh;branch=main/g' meta-core/meta-restricted/recipes-intel/telemetry/pmt_git.bb

	sed -i 's/git.ami.com\/core\/ami-bmc\/one-tree\/intel\/firmware.bmc.openbmc.applications.mmbi-seamless.git;protocol=ssh;branch=main/git@github.com\/intel-bmc\/firmware.bmc.openbmc.applications.mmbi-seamless.git;protocol=ssh;branch=main/g' meta-core/meta-restricted/recipes-intel/seamless/mmbi-seamless.bb

	sed -i 's/git.ami.com\/core\/ami-bmc\/one-tree\/intel\/firmware.bmc.openbmc.applications.trusted-application.git;protocol=ssh;nobranch=1/git@github.com\/intel-bmc\/firmware.bmc.openbmc.applications.trusted-application.git;protocol=ssh;nobranch=1/g' meta-core/meta-restricted/recipes-optee/optee-user-ta/optee-user-ta_git.bb

	sed -i 's/git.ami.com\/core\/ami-bmc\/one-tree\/intel\/firmware.bmc.openbmc.applications.ondemand.git;protocol=ssh;branch=main/git@github.com\/intel-bmc\/firmware.bmc.openbmc.applications.ondemand.git;protocol=ssh;branch=main/g' meta-core/meta-restricted/recipes-intel/oob-config/ondemand_git.bb

else
	echo "INFO : meta-restricted does not exists."
fi

if [ -d "meta-core/meta-intel" ]; then
	sed -i 's/git.ami.com\/core\/ami-bmc\/one-tree\/core\/firmware.bmc.openbmc.applications.mtd-util.git;protocol=ssh;branch=main/git@github.com\/intel-bmc\/firmware.bmc.openbmc.applications.mtd-util.git;protocol=ssh;branch=main/g' meta-core/meta-intel/recipes-devtools/mtd-util/mtd-util.bb
	sed -i 's/git.ami.com\/core\/ami-bmc\/one-tree\/core\/firmware.bmc.openbmc.applications.intel-pfr-signing-utility.git;protocol=ssh;branch=main/git@github.com\/intel-bmc\/firmware.bmc.openbmc.applications.intel-pfr-signing-utility.git;protocol=ssh;branch=main/g' meta-core/meta-intel/recipes-intel/intel-pfr/intel-pfr-signing-utility-native.bb
	sed -i 's/git.ami.com\/core\/ami-bmc\/one-tree\/core\/firmware.bmc.openbmc.applications.secure-control-module-i2c-memory-map.git;protocol=ssh;branch=main/git@github.com\/intel-bmc\/firmware.bmc.openbmc.applications.secure-control-module-i2c-memory-map.git;protocol=ssh;branch=main/g' meta-core/meta-intel/recipes-intel/scm-i2c-memory-map/scm-i2c-memory-map.bb

	sed -i 's/git.ami.com\/core\/ami-bmc\/one-tree\/core\/firmware.bmc.openbmc.applications.domain-mapperd.git;protocol=ssh;branch=main/git@github.com\/intel-bmc\/firmware.bmc.openbmc.applications.domain-mapperd.git;protocol=ssh;branch=main/g' meta-core/meta-intel/recipes-intel/domain-mapperd/domain-mapperd.bb

	sed -i 's/git.ami.com\/intel-collab\/firmware.bmc.openbmc.applications.dimm-devices-accessor.git;protocol=ssh;branch=main/git@github.com\/intel-bmc\/firmware.bmc.openbmc.applications.dimm-devices-accessor.git;protocol=ssh;branch=main/g' meta-core/meta-intel/recipes-intel/dimm-devices-accessor/dimm-devices-accessor.bb

	sed -i 's/git.ami.com\/core\/ami-bmc\/one-tree\/core\/firmware.bmc.openbmc.applications.dimm-devices-accessor.git;protocol=ssh;branch=main/git@github.com\/intel-collab\/firmware.bmc.openbmc.applications.dimm-devices-accessor.git;protocol=ssh;branch=main/g' meta-core/meta-intel/recipes-intel/dimm-devices-accessor/dimm-devices-accessor.bb
	sed -i 's/git.ami.com\/core\/ami-bmc\/one-tree\/core\/firmware.bmc.openbmc.libraries.libpmt.git;protocol=ssh;branch=main/git@github.com\/intel-bmc\/firmware.bmc.openbmc.libraries.libpmt.git;protocol=ssh;branch=main/g' meta-core/meta-intel/recipes-intel/pmt/libpmt_git.bb
	
	sed -i 's/git.ami.com\/core\/ami-bmc\/one-tree\/core\/firmware.bmc.openbmc.applications.power-feature-discovery.git;protocol=ssh;branch=main/git@github.com\/intel-bmc\/firmware.bmc.openbmc.applications.power-feature-discovery.git;protocol=ssh;branch=main/g' meta-core/meta-intel/recipes-intel/power-feature-discovery/power-feature-discovery_git.bb

else
	echo "INFO : meta-intel does not exists."
fi
