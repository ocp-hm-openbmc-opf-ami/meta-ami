SUMMARY = "Custom native LED config for EVB-2700"
DESCRIPTION = "Provides led.yaml in native sysroot for phosphor-led-manager build"

LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/files/common-licenses/Apache-2.0;md5=89aea4e17d99a7cacdbeed46a0096b10"

inherit native

PROVIDES += "virtual/phosphor-led-manager-config-native"

SRC_URI += "file://led.yaml"

S = "${WORKDIR}"

do_install() {
    install -d ${D}${datadir}/phosphor-led-manager
    install -m 0644 ${S}/led.yaml ${D}${datadir}/phosphor-led-manager/led.yaml
}
