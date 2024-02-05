FILESEXTRAPATHS:append:= "${THISDIR}/files:"

#Overriding init script
SRC_URI += "file://obmc-init.sh"
SRC_URI += "file://obmc-update.sh"

RDEPENDS:${PN} += "cryptsetup"
# flash_eraseall
RDEPENDS:${PN} += "mtd-utils"
