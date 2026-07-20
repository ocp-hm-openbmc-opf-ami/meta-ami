SUMMARY = "Phosphor LED Group Management for EVB-2700"
PR = "r1"

inherit obmc-phosphor-utils
inherit native

LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/files/common-licenses/Apache-2.0;md5=89aea4e17d99a7cacdbeed46a0096b10"

PROVIDES += "virtual/phosphor-led-manager-config-native"

SRC_URI += "file://led-group-config.json"

# Copies example led layout json file
do_install() {
    SRC=${UNPACKDIR}
    install -d ${D}${datadir}/phosphor-led-manager
    install -m 0644 ${SRC}/led-group-config.json ${D}${datadir}/phosphor-led-manager/led-group-config.json
}
