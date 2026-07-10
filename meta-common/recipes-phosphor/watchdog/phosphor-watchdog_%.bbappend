FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRCREV = "7ef378d31bf645d9b87c435fa94095e8d2ed7048"

SRC_URI += "file://phosphor-watchdog.service \
            file://phosphor-watchdog@.service \
           "

DEPENDS:append = " libpdkhook "
RDEPENDS:${PN}:append = " libpdkhook "

# Indices to use based on the feature
WATCHDOG_MULTIHOST = "${@ '1' if ( \
    bb.utils.contains('EXTRA_IMAGE_FEATURES', 'onetree-multi-host-support', True, False, d) and \
    d.getVar('MULTI_HOST_DEFAULT_MODE') == '1' \
) else '0'}"

# Expand to actual systemd units
SYSTEMD_SERVICE:${PN} = "${@bb.utils.contains('WATCHDOG_MULTIHOST', '1', \
    'phosphor-watchdog@host1.service phosphor-watchdog@host2.service', \
    'phosphor-watchdog.service', d)}"

do_install:append() {
    install -d ${D}${systemd_system_unitdir}
    if ${@bb.utils.contains('WATCHDOG_MULTIHOST', '1', 'true', 'false', d)}; then
        rm -f ${D}${systemd_system_unitdir}/phosphor-watchdog.service
        install -m 0644 ${UNPACKDIR}/phosphor-watchdog@.service \
            ${D}${systemd_system_unitdir}/
    else
        rm -f ${D}${systemd_system_unitdir}/phosphor-watchdog@.service
        install -m 0644 ${UNPACKDIR}/phosphor-watchdog.service \
            ${D}${systemd_system_unitdir}/
    fi
}
