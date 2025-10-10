FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"
PROJECT_SRC_DIR := "${THISDIR}/${PN}"

# The URI is required for the autobump script but keep it commented
# to not override the upstream value
# SRC_URI += "git://github.com/openbmc/phosphor-host-ipmid;branch=master;protocol=https"
SRCREV = "ea46f3ca61dd12b210a74cf78e464c78e0987a47"
SRC_URI += "file://phosphor-ipmi-host.service \
            file://transporthandler_oem.cpp \
           "

INTEL_SRC_URI += "\
            file://0053-Fix-keep-looping-issue-when-entering-OS.patch \
            file://0063-Save-the-pre-timeout-interrupt-in-dbus-property.patch \
            "
SRC_URI:append = "${@bb.utils.contains('BBFILE_COLLECTIONS', 'meta-ami', '',INTEL_SRC_URI, d)}"

PACKAGECONFIG:append = " transport-oem "
PACKAGECONFIG:remove = "allowlist"
PACKAGECONFIG:remove = "i2c-allowlist"
PACKAGECONFIG:remove = "boot-flag-safe-mode"

RDEPENDS:${PN}:remove:intel-ast2600 = "clear-once"
# remove the softpoweroff service since we do not need it
SYSTEMD_SERVICE:${PN}:remove = " \
    xyz.openbmc_project.Ipmi.Internal.SoftPowerOff.service"

SYSTEMD_LINK:${PN}:remove = " \
    ../xyz.openbmc_project.Ipmi.Internal.SoftPowerOff.service:obmc-host-shutdown@0.target.requires/xyz.openbmc_project.Ipmi.Internal.SoftPowerOff.service \
    "

# remove dependencies from main recipe since we control it with local service file
unset IPMI_HOST_NEEDED_SERVICES

do_configure:prepend(){
    cp -f ${PROJECT_SRC_DIR}/transporthandler_oem.cpp ${S}
}

do_install:append(){
    rm -f ${D}/${bindir}/phosphor-softpoweroff
}

