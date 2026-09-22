FILESEXTRAPATHS:append := "${THISDIR}/files:"
PR = "r1"
LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/files/common-licenses/Apache-2.0;md5=89aea4e17d99a7cacdbeed46a0096b10"

inherit allarch
inherit phosphor-dbus-monitor


S = "${UNPACKDIR}"


SRC_URI = "file://host-reset.json"

do_install() {

   install -d ${D}${sysconfdir}/xyz/openbmc_project/phosphor-dbus-monitor/
   install -m 0644 ${UNPACKDIR}/host-reset.json ${D}${sysconfdir}/xyz/openbmc_project/phosphor-dbus-monitor/
}

FILES:${PN} += "${sysconfdir}/xyz/openbmc_project/phosphor-dbus-monitor/*"
