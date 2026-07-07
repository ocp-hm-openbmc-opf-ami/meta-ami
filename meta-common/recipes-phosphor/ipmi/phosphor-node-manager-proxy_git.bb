SUMMARY = "Node Manager Proxy"
DESCRIPTION = "The Node Manager Proxy provides a simple interface for communicating \
with Management Engine via IPMB"

SRC_URI = "git://git@github.com/ocp-hm-openbmc-opf-ami/node-manager-proxy.git;protocol=https;branch=main"
SRCREV = "3a1244c692c250b843546eb5fb6750c5180e5c43"
PV = "0.1+git${SRCPV}"

LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/files/common-licenses/Apache-2.0;md5=89aea4e17d99a7cacdbeed46a0096b10"

SYSTEMD_SERVICE:${PN} = "node-manager-proxy.service"

DEPENDS = "sdbusplus \
           phosphor-logging \
           boost"

S = "${UNPACKDIR}/git"
inherit cmake systemd pkgconfig
