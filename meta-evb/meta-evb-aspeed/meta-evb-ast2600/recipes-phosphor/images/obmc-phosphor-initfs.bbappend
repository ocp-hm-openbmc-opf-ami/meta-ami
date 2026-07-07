FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

#Overriding init script
SRC_URI += "file://obmc-init.sh"
SRC_URI += "file://obmc-update.sh"
SRC_URI += "file://common-conf-obmc-init.sh"

RDEPENDS:${PN} += "cryptsetup"
# flash_eraseall
RDEPENDS:${PN} += "mtd-utils"

do_install:append() {
    if [ -f "${D}/whitelist" ]; then
        # Append two new lines to the file
        echo "/etc/license-control/token" >> "${D}/whitelist"
        echo "/etc/license-control/license.json" >> "${D}/whitelist"
    fi

    if ${@bb.utils.contains('IMAGE_FEATURES', 'onetree-dual-image-common-conf', 'true', 'false', d)}; then
        install -m 0755 ${UNPACKDIR}/common-conf-obmc-init.sh ${D}/init
    fi
}
