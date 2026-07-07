FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"
SRC_URI:append = " \
    file://fstab \
    file://40-oom_reboot.conf \
    "

add_oom_reboot_config() {
    install -d ${D}/${libdir}/sysctl.d
    install -D -m 644 ${UNPACKDIR}/40-oom_reboot.conf ${D}/${libdir}/sysctl.d/40-oom_reboot.conf
}

do_install:append() {
    ${@bb.utils.contains('EXTRA_IMAGE_FEATURES', 'allow-root-login', '', 'add_oom_reboot_config', d)}
}

