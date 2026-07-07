FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI += "file://enable-ssh.sh \
            "

do_install:append() {
    install -m 0755 ${UNPACKDIR}/enable-ssh.sh ${D}${bindir}/
}

# Enable dropbear.socket and dropbearkey.service only for allow-root-login
SYSTEMD_AUTO_ENABLE:${PN} = "${@bb.utils.contains('EXTRA_IMAGE_FEATURES', 'allow-root-login', 'enable', 'disable', d)}"

# Since not enabling last in busybox, don't use lastlog
EXTRA_OECONF:append = " --disable-wtmp --disable-utmp --disable-lastlog"
