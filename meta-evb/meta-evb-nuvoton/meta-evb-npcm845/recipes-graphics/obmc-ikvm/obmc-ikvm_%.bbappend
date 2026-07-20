FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

LIC_FILES_CHKSUM = "file://LICENSE;md5=75859989545e37968a99b631ef42722e"
SRC_URI:nuvoton := "git://github.com/Nuvoton-Israel/obmc-ikvm.git;branch=upstream-v4l2;protocol=https \
                    file://0001-Nuvoton-service-name-change.patch"
SRCREV:nuvoton := "0f73cf51b823e3e7a0194fe49844ca9c1b75df1b"


SYSTEMD_SERVICE:${PN}:remove = "obmc-ikvm.service"
SYSTEMD_SERVICE:${PN} += "start-ipkvm.service"
FILES:${PN} += "${systemd_system_unitdir}/start-ipkvm.service.d"