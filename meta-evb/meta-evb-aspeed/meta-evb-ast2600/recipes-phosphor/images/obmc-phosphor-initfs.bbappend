FILESEXTRAPATHS:append:= "${THISDIR}/files:"

#Overriding init script
SRC_URI += "file://obmc-init.sh"
SRC_URI += "file://obmc-update.sh"

RDEPENDS:${PN} += "cryptsetup"
# flash_eraseall
RDEPENDS:${PN} += "mtd-utils"

do_install:append() {
    if [ -f "${D}/whitelist" ]; then
        # Append two new lines to the file
        echo "/etc/license-control/token" >> "${D}/whitelist"
        echo "/etc/license-control/license.json" >> "${D}/whitelist"
    fi
}
