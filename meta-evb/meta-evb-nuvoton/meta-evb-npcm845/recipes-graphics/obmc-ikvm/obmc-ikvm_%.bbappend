FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

LIC_FILES_CHKSUM = "file://LICENSE;md5=75859989545e37968a99b631ef42722e"
SRC_URI:nuvoton := "git://github.com/Nuvoton-Israel/obmc-ikvm.git;branch=upstream-v4l2;protocol=https"
SRCREV:nuvoton := "b0e214b22d50a87e5379507d25f4c3bbeb099d53"

FILES:${PN} += "${systemd_system_unitdir}/start-ipkvm.service.d"
