SUMMARY = "Host interface initialization"
SECTION = "application"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"
RDEPENDS:${PN} = "systemd bash"

SRC_URI = " \
    file://create_usbeth.sh \
    file://host-interface.service \
    "
SRC_URI += "${@bb.utils.contains('EXTRA_IMAGE_FEATURES', 'onetree-multi-host-support', \
    'file://create_usbeth1.sh file://host-interface1.service', '', d)}"

S = "${WORKDIR}/git"

inherit allarch systemd

SYSTEMD_SERVICE:${PN} = "host-interface.service"
SYSTEMD_SERVICE:${PN} += "${@bb.utils.contains('EXTRA_IMAGE_FEATURES', 'onetree-multi-host-support', \
    'host-interface1.service', '', d)}"

do_install() {
    install -d ${D}${bindir}
    install -m 0755 ${UNPACKDIR}/create_usbeth.sh  ${D}${bindir}
    install -d ${D}${base_libdir}/systemd/system
    install -m 0644 ${UNPACKDIR}/host-interface.service ${D}${base_libdir}/systemd/system

    if ${@bb.utils.contains('EXTRA_IMAGE_FEATURES', 'onetree-multi-host-support', 'true', 'false', d)}; then
        install -m 0755 ${UNPACKDIR}/create_usbeth1.sh ${D}${bindir}
        install -m 0644 ${UNPACKDIR}/host-interface1.service ${D}${base_libdir}/systemd/system
    fi
}
