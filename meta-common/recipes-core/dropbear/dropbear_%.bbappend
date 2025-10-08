FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI += "file://enable-ssh.sh \
            "

do_install:append() {
    install -m 0755 ${WORKDIR}/enable-ssh.sh ${D}${bindir}/
}

# Enable dropbear.socket and dropbearkey.service only for debug-tweaks
SYSTEMD_AUTO_ENABLE:${PN} = "${@bb.utils.contains('EXTRA_IMAGE_FEATURES', 'debug-tweaks', 'enable', 'disable', d)}"
