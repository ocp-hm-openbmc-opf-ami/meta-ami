# Sync to the latest x86-power-control. We can remove it after rebasing OpenBMC.
#SRCREV = "05e8ea8e3c834f2bd029647930dd8c139486bada"
FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI += " \
            file://0001-Removed-NMI-SIO_PWR_GOOD-ID_BUTTON.patch \
            file://power-config-host0.json \
            file://power-config-host1.json \
            file://power-config-host2.json \
           "

# Indices to use based on the feature
OBMC_HOST_INSTANCES = "${@ '1 2' if ( \
    bb.utils.contains('EXTRA_IMAGE_FEATURES', 'onetree-multi-host-support', True, False, d) and \
    d.getVar('MULTI_HOST_DEFAULT_MODE', True) == '1' \
) else '0'}"

do_install:append() {
    if ${@bb.utils.contains('OBMC_HOST_INSTANCES', '1 2', 'true', 'false', d)}; then
	rm -f ${D}${datadir}/${PN}/power-config-host0.json
	install -m 0644 ${UNPACKDIR}/power-config-host1.json ${D}${datadir_native}/x86-power-control/
	install -m 0644 ${UNPACKDIR}/power-config-host2.json ${D}${datadir_native}/x86-power-control/
    else
	install -m 0644 ${UNPACKDIR}/power-config-host0.json ${D}${datadir_native}/x86-power-control/
    fi
}
