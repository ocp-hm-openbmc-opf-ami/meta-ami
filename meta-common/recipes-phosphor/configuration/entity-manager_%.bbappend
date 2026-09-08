FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI += "git://git@github.com/ocp-hm-openbmc-opf-ami/entity-manager.git;branch=integrate-onetree-3.1.1;protocol=https;name=override;"
SRCREV_FORMAT = "override"
SRCREV_override = "3b082bca48274c0cdac3f8942d1b5bbfe87f5c12"

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


