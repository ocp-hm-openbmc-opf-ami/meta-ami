FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI += "git://git.ami.com/core/ami-bmc/one-tree/core/phosphor-dbus-interfaces.git;branch=main;protocol=https;name=override;"
SRCREV_FORMAT = "override"
SRCREV_override = "5033fb2ce543b8849038ecb1fa61a8625616cf10"

SRC_URI += "file://0036-EnhancedPasswordPolicy.patch \
            file://0005-Add-Bootstrap-credential-support.patch \
            file://0006-Add-Diag-Arugment-in-Boot-Mode-Interface.patch \
            file://0010-Added-TimeOut-for-managers.patch \
            file://0012-Certificate-dbus-renew-rekey.patch \
            file://0012-passwordChangeRequired.patch \
            file://0037-backupRestore.patch \
            file://0018-snmp-agent.patch \
        "

EXTRA_OEMESON += "-Ddata_com_ami=true"
EXTRA_OEMESON += "-Ddata_org_open_power=true"

