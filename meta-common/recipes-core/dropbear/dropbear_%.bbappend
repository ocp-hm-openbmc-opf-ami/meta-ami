FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI += "file://enable-ssh.sh \
            "

do_install:append() {
    install -m 0755 ${WORKDIR}/enable-ssh.sh ${D}${bindir}/
}

# Enable dropbear.socket and dropbearkey.service only for debug-tweaks
SYSTEMD_AUTO_ENABLE:${PN} = "${@bb.utils.contains('EXTRA_IMAGE_FEATURES', 'debug-tweaks', 'enable', 'disable', d)}"

# Since not enabling last in busybox, don't use lastlog
EXTRA_OECONF:append = " --disable-wtmp --disable-utmp --disable-lastlog"
