FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

DEPENDS = "boost \
           dbus \
           nlohmann-json \
           phosphor-logging \
           sdbusplus \
           valijson \
           phosphor-dbus-interfaces \
"


SRC_URI:append = " \
    file://solum_pssf162202_psu.json \
    file://cpld.json \
    file://preserve_configuration.json \
    file://preserve_network_configuration.json \
    file://0001-Entity-manager-Add-support-to-update-assetTag.patch \
    file://0002-Add-Config-FRU-Support.patch \
    file://0003-add-new-interface-for-partial-preserve-config-suppor.patch \
    file://0004-Added-Fix-For-SDR-Preserve-Configuration.patch \
    file://0005-Added-Test-Fru-Feature.patch \
    file://0007-Add-condition-for-journal-error-and-info-handling.patch \
    file://0008-Converting-journal-log-into-dbus.patch \
    file://0009-Added-fix-for-SDR-Fail.patch \
    file://0010-FruRescan-SDR-Fix.patch \
    file://0011-Reverting-community-patch-for-Preserve-config-failure.patch \
    "

SRCREV = "eb760950130197db661710ca8489c60f16ca38d9"

PACKAGECONFIG[dts-vpd] = "-Ddevicetree-vpd=true, -Ddevicetree-vpd=false"
PACKAGECONFIG[ipmi-fru] = "-Dfru-device=true, -Dfru-device=false, i2c-tools"

SYSTEMD_SERVICE:devicetree-vpd = "devicetree-vpd-parser.service"
SYSTEMD_SERVICE:fru-device = "xyz.openbmc_project.FruDevice.service"

EXTRA_ENTITY_MANAGER_PACKAGES = " \
    ${@bb.utils.contains('PACKAGECONFIG', 'dts-vpd', 'devicetree-vpd', '', d)} \
    ${@bb.utils.contains('PACKAGECONFIG', 'ipmi-fru', 'fru-device', '', d)} \
    "

PACKAGECONFIG:append = " dts-vpd"

FILES:devicetree-vpd = "${bindir}/devicetree-vpd-parser"

EXTRA_OEMESON:append = " -Dfru-device-resizefru=true"

#EXTRA_OEMESON:append = " -Dtest-fru=true"

do_install:append(){
     install -m 0444 ${WORKDIR}/cpld.json ${D}/usr/share/entity-manager/configurations
     install -m 0444 ${WORKDIR}/preserve_configuration.json ${D}/usr/share/entity-manager/configurations
     install -m 0444 ${WORKDIR}/preserve_network_configuration.json ${D}/usr/share/entity-manager/configurations
     install -m 0644 ${WORKDIR}/solum_pssf162202_psu.json \
            ${D}${datadir}/entity-manager/configurations/solum_pssf162202_psu.json
}

