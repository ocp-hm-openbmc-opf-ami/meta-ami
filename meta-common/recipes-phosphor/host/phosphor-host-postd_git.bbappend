FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI += "\
            file://0001-Intergrating-SBMR-boot-progress-code-support-to-lpcs.patch \
            file://0002-Switch-SBMR-BootProgress-to-byte-arrays-and-fix-inde.patch \
            file://0003-Added-support-for-four-byte-postcode-using-PCC-devic.patch \
            file://0004-Add-support-for-multi-host-PCC-with-dynamic-object.patch \
            file://lpcsnoop@.service \
            "
SRCREV = "b59c07b475141f08ab0c5dd44a6ce995bb5a6f6b"

# Indices to use based on the feature
POSTD_MULTIHOST = "${@ '1' if ( \
    bb.utils.contains('EXTRA_IMAGE_FEATURES', 'onetree-multi-host-support', True, False, d) and \
    d.getVar('MULTI_HOST_DEFAULT_MODE') == '1' \
) else '0'}"

SYSTEMD_SERVICE:${PN} = "${@bb.utils.contains('POSTD_MULTIHOST', '1', \
    'lpcsnoop@1.service lpcsnoop@2.service', \
    'lpcsnoop.service', d)}"

FILES:${PN}:append = " ${@bb.utils.contains('POSTD_MULTIHOST', '1', \
    '${systemd_system_unitdir}/lpcsnoop@.service', '', d)}"

do_install:append() {
    install -d ${D}${systemd_system_unitdir}
    if ${@bb.utils.contains('POSTD_MULTIHOST', '1', 'true', 'false', d)}; then
        rm -f ${D}${systemd_system_unitdir}/lpcsnoop.service
        install -m 0644 ${UNPACKDIR}/lpcsnoop@.service ${D}${systemd_system_unitdir}/
    fi
}
