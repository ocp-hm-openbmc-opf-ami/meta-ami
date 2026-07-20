FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

RDEPENDS:${PN} += "bash"

SRC_URI += " \
             file://pfr_update.sh \
           "

# Enable flash_bios for PFR firmware update.
PACKAGECONFIG:append = " verify_signature flash_bios"

# Append PFR-specific images to the base OPTIONAL_IMAGES variable
OPTIONAL_IMAGES:append = ",bios_signed_cap.bin,bmc_signed_cap.bin,zephyr_signed.bin"

do_install:append() {
    install -d ${D}/usr/sbin
    install -m 0755 ${UNPACKDIR}/pfr_update.sh ${D}/usr/sbin/pfr_update.sh
}
