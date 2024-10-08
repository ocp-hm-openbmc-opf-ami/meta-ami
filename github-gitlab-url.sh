#!/bin/sh

sed -i 's/openbmc-meta-intel/meta-common/g' meta-common/meta-common/recipes-intel/packagegroups/packagegroup-intel-apps.bb

sed -i 's/git.ami.com\/core\/ami-bmc\/one-tree\/core\/obmc-ikvm;branch=main;protocol=https/git@github.com\/ocp-hm-openbmc-opf-ami\/obmc-ikvm;protocol=https;branch=main/g' meta-ami/meta-common/recipes-graphics/obmc-ikvm/obmc-ikvm_%.bbappend

sed -i 's/git.ami.com\/core\/ami-bmc\/one-tree\/core\/phosphor-dbus-interfaces.git;branch=main;protocol=https;name=override/git@github.com\/ocp-hm-openbmc-opf-ami\/phosphor-dbus-interfaces;protocol=https;branch=main;name=override/g' meta-ami/meta-common/recipes-phosphor/dbus/phosphor-dbus-interfaces_%.bbappend

sed -i 's/git.ami.com\/core\/ami-bmc\/one-tree\/core\/intel-ipmi-oem.git;branch=master;protocol=https;name=override/git@github.com\/ocp-hm-openbmc-opf-ami\/intel-ipmi-oem;protocol=https;branch=master;name=override/g' meta-ami/meta-common/recipes-phosphor/ipmi/intel-ipmi-oem_%.bbappend

sed -i 's/git.ami.com\/core\/ami-bmc\/one-tree\/core\/phosphor-host-ipmid.git;branch=master;protocol=https;name=override/git@github.com\/ocp-hm-openbmc-opf-ami\/phosphor-host-ipmid;protocol=https;branch=master;name=override/g' meta-ami/meta-common/recipes-phosphor/ipmi/phosphor-ipmi-host_%.bbappend

sed -i 's/git.ami.com\/core\/ami-bmc\/one-tree\/core\/webui-vue.git;branch=main;protocol=https/git@github.com\/ocp-hm-openbmc-opf-ami\/webui-vue;protocol=https;branch=main/g' meta-ami/meta-common/recipes-phosphor/webui/webui-vue_%.bbappend

sed -i 's/git.ami.com\/core\/ami-bmc\/one-tree\/core\/dbus-sensors.git;branch=master;protocol=https;name=override/git@github.com\/ocp-hm-openbmc-opf-ami\/dbus-sensors;protocol=https;branch=master;name=override/g' meta-ami/meta-common/recipes-phosphor/sensors/dbus-sensors_%.bbappend

sed -i 's/git.ami.com\/core\/ami-bmc\/one-tree\/core\/snmp-agent.git;branch=main;protocol=https/git@github.com\/ocp-hm-openbmc-opf-ami\/snmp-agent;protocol=https;branch=main/g' meta-ami/meta-common/recipes-phosphor/snmp/snmp-agent_%.bb


sed -i 's/git.ami.com\/core\/ami-bmc\/one-tree\/core\/license-control.git;protocol=https;branch=main/git@github.com\/ocp-hm-openbmc-opf-ami\/license-control.git;protocol=https;branch=main/g' meta-ami/meta-common/recipes-ami/license-control/license-control.bb

sed -i 's/git.ami.com\/core\/ami-bmc\/one-tree\/core\/platform-event-filter.git;protocol=https;branch=main/git@github.com\/ocp-hm-openbmc-opf-ami\/platform-event-filter.git;protocol=https;branch=main/g' meta-ami/meta-common/recipes-ami/pef/pef-alert-manager.bb
    
sed -i 's/git.ami.com\/core\/ami-bmc\/one-tree\/core\/sensor-history-reader.git;protocol=https;branch=master/git@github.com\/ocp-hm-openbmc-opf-ami\/sensor-history-reader.git;protocol=https;branch=master/g' meta-ami/meta-common/recipes-intel/sensor-reader/sensor-reader_git.bb


sed -i 's/git.ami.com\/core\/ami-bmc\/one-tree\/core\/backup-restore.git;protocol=https;branch=main/git@github.com\/ocp-hm-openbmc-opf-ami\/backup-restore.git;protocol=https;branch=main/g' meta-ami/meta-common/recipes-phosphor/backup/backuprestore_git.bb

sed -i 's/git.ami.com\/core\/ami-bmc\/one-tree\/core\/email-alert-manager.git;protocol=https;branch=main/git@github.com\/ocp-hm-openbmc-opf-ami\/email-alert-manager.git;protocol=https;branch=main/g' meta-ami/meta-common/recipes-ami/pef/mail-alert-manager.bb


sed -i 's/git@github.com\/intel-bmc\/firmware.bmc.openbmc.applications.host-misc-comm-manager;protocol=ssh;branch=main/git@github.com\/ocp-hm-openbmc-opf-ami\/host-misc-comm-manager;protocol=https;branch=main/g' meta-common/meta-common/recipes-intel/host-misc-comm-manager/host-misc-comm-manager_git.bb

sed -i 's/git@github.com\/intel-bmc\/firmware.bmc.openbmc.applications.psu-manager.git;protocol=ssh;branch=main/git@github.com\/ocp-hm-openbmc-opf-ami\/psu-manager.git;protocol=https;branch=main/g' meta-common/meta-common/recipes-intel/psu-manager/psu-manager.bb

sed -i 's/git@github.com\/intel-bmc\/os.linux.kernel.openbmc.linux.git;protocol=ssh;branch=${KBRANCH}/git@github.com\/ocp-hm-openbmc-opf-ami\/linux.git;protocol=https;branch=${KBRANCH}/g' meta-common/meta-common/recipes-kernel/linux/linux-aspeed_%.bbappend

sed -i 's/git@github.com\/intel-collab\/firmware.bmc.openbmc.applications.node-manager-proxy.git;protocol=ssh;branch=main/git@github.com\/ocp-hm-openbmc-opf-ami\/node-manager-proxy.git;protocol=https;branch=main/g' meta-common/meta-common/recipes-phosphor/ipmi/phosphor-node-manager-proxy_git.bb

sed -i 's/git@github.com\/intel-bmc\/firmware.bmc.openbmc.libraries.libmctp.git;protocol=ssh;branch=main/git@github.com\/ocp-hm-openbmc-opf-ami\/libmctp.git;protocol=https;branch=main/g' meta-common/meta-common/recipes-phosphor/pmci/libmctp-intel_git.bb

sed -i 's/git@github.com\/intel-bmc\/firmware.bmc.openbmc.libraries.libpldm.git;protocol=ssh;branch=main/git@github.com\/ocp-hm-openbmc-opf-ami\/libpldm.git;protocol=https;branch=main/g' meta-common/meta-common/recipes-phosphor/pmci/libpldm-intel_git.bb

sed -i 's/git@github.com\/intel-bmc\/firmware.bmc.openbmc.libraries.mctp-wrapper.git;protocol=ssh;branch=main/git@github.com\/ocp-hm-openbmc-opf-ami\/mctp-wrapper.git;protocol=https;branch=main/g' meta-common/meta-common/recipes-phosphor/pmci/mctp-wrapper.bb

sed -i 's/git@github.com\/intel-bmc\/firmware.bmc.openbmc.applications.mctpd.git;protocol=ssh;branch=main/git@github.com\/ocp-hm-openbmc-opf-ami\/mctpd.git;protocol=https;branch=main/g' meta-common/meta-common/recipes-phosphor/pmci/mctpd.bb

sed -i 's/git@github.com\/intel-bmc\/firmware.bmc.openbmc.libraries.mctpwplus.git;protocol=ssh;branch=main/git@github.com\/ocp-hm-openbmc-opf-ami\/mctpwplus.git;protocol=https;branch=main/g' meta-common/meta-common/recipes-phosphor/pmci/mctpwplus.bb

sed -i 's/git@github.com\/intel-bmc\/firmware.bmc.openbmc.applications.nvme-mi-daemon.git;protocol=ssh;branch=main/git@github.com\/ocp-hm-openbmc-opf-ami\/nvme-mi-daemon.git;protocol=https;branch=main/g' meta-common/meta-common/recipes-phosphor/pmci/nvmemi-daemon.bb

sed -i 's/git@github.com\/intel-bmc\/firmware.bmc.openbmc.applications.pldmd.git;protocol=ssh;branch=main/git@github.com\/ocp-hm-openbmc-opf-ami\/pldmd.git;protocol=https;branch=main/g' meta-common/meta-common/recipes-phosphor/pmci/pldmd.bb

sed -i 's/git@github.com\/intel-bmc\/firmware.bmc.openbmc.applications.pmci-launcher.git;protocol=ssh;branch=main/git@github.com\/ocp-hm-openbmc-opf-ami\/pmci-launcher.git;protocol=https;branch=main/g' meta-common/meta-common/recipes-phosphor/pmci/pmci-launcher.bb

sed -i 's/git@github.com\/intel-bmc\/firmware.bmc.openbmc.applications.provisioning-mode-manager.git;protocol=ssh;branch=main/git@github.com\/ocp-hm-openbmc-opf-ami\/provisioning-mode-manager.git;protocol=https;branch=main/g' meta-common/meta-common/recipes-phosphor/prov-mode-mgr/prov-mode-mgr_git.bb

sed -i 's/git@github.com\/intel-bmc\/firmware.bmc.openbmc.applications.security-manager.git;protocol=ssh;branch=main/git@github.com\/ocp-hm-openbmc-opf-ami\security-manager.git;protocol=https;branch=main/g' meta-common/meta-common/recipes-phosphor/security-manager/security-manager_git.bb

sed -i 's/git@github.com\/intel-bmc\/firmware.bmc.openbmc.applications.settings-manager.git;protocol=ssh;branch=main/git@github.com\/ocp-hm-openbmc-opf-ami\/settings-manager.git;protocol=https;branch=main/g' meta-common/meta-common/recipes-phosphor/settings/settings_git.bb

sed -i 's/git@github.com\/intel-bmc\/firmware.bmc.openbmc.applications.special-mode-manager.git;protocol=ssh;branch=main/git@github.com\/ocp-hm-openbmc-opf-ami\/special-mode-manager.git;protocol=https;branch=main/g' meta-common/meta-common/recipes-phosphor/special-mode-mgr/special-mode-mgr_git.bb

sed -i 's/git@github.com\/intel-bmc\/firmware.bmc.openbmc.applications.virtual-media.git;protocol=ssh;branch=main/git@github.com\/ocp-hm-openbmc-opf-ami\/virtual-media.git;protocol=https;branch=main/g' meta-common/meta-common/recipes-phosphor/virtual-media/virtual-media.bb

sed -i 's/git@github.com\/intel-collab\/firmware.bmc.openbmc.applications.mctp-emulator.git;protocol=ssh;branch=main/git@github.com\/ocp-hm-openbmc-opf-ami\/mctp-emulator.git;protocol=https;branch=main/g' meta-common/meta-common/recipes-phosphor/pmci/mctp-emulator.bb

sed -i 's/git@github.com\/intel-bmc\/firmware.bmc.openbmc.libraries.libespi.git;protocol=ssh;branch=main/git@github.com\/ocp-hm-openbmc-opf-ami\/libespi.git;protocol=https;branch=main/g' meta-common/meta-common/recipes-core/libespi/libespi_git.bb
