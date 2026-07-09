FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI += "git://git.ami.com/core/ami-bmc/one-tree/core/entity-manager.git;branch=master;protocol=https;name=override;"
SRCREV_FORMAT = "override"
SRCREV_override = "e7388b113fade819bb8aa1f2ccd3362254b0b21e"

SRC_URI:append = " \
    file://cpld.json \
    file://preserve_configuration.json \
    file://preserve_network_configuration.json \
    file://cxlchassis.json \
    file://cxltype3.json \
    file://cxlsystem.json \
    file://artesyn_psu.json \
    "

PACKAGECONFIG ??= "ipmi-fru"

EXTRA_OEMESON:append = " -Dfru-device-resizefru=true"

#EXTRA_OEMESON:append = " -Dtest-fru=true"


do_install:append(){
     install -m 0444 ${UNPACKDIR}/cpld.json ${D}/usr/share/entity-manager/configurations
     install -m 0444 ${UNPACKDIR}/preserve_configuration.json ${D}/usr/share/entity-manager/configurations
     install -m 0444 ${UNPACKDIR}/preserve_network_configuration.json ${D}/usr/share/entity-manager/configurations
     install -m 0444 ${UNPACKDIR}/cxlchassis.json ${D}/usr/share/entity-manager/configurations
     install -m 0444 ${UNPACKDIR}/cxltype3.json ${D}/usr/share/entity-manager/configurations
     install -m 0444 ${UNPACKDIR}/cxlsystem.json ${D}/usr/share/entity-manager/configurations
     install -m 0644 ${UNPACKDIR}/artesyn_psu.json \
            ${D}${datadir}/entity-manager/configurations/artesyn_psu.json
}


