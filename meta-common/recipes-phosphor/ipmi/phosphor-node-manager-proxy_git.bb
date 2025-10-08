SUMMARY = "Node Manager Proxy"
DESCRIPTION = "The Node Manager Proxy provides a simple interface for communicating \
with Management Engine via IPMB"

SRC_URI = "git://git@github.com/intel-collab/firmware.bmc.openbmc.applications.node-manager-proxy.git;protocol=ssh;branch=main"
SRCREV = "55df898451f74bf38550b006ec999218d4726773"
PV = "0.1+git${SRCPV}"

LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/files/common-licenses/Apache-2.0;md5=89aea4e17d99a7cacdbeed46a0096b10"

SYSTEMD_SERVICE:${PN} = "node-manager-proxy.service"

DEPENDS = "sdbusplus \
           phosphor-logging \
           boost"

S = "${WORKDIR}/git"
inherit cmake systemd pkgconfig
