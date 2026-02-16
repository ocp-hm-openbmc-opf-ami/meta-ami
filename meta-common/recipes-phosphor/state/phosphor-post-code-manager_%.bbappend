FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"
SRC_URI += "\
               file://0001-fix-bootcount-increment.patch \
               file://0002-MSFT-Phosphor-Post-Code-Manager-Intergration.patch \
               file://0003-throw-error-if-max-boot-cycle-exceeded.patch \
               file://0004-Ensure-proper-sequencing-of-PostCode-logs.patch \
               file://0005-Fixed-Postcode-Boot-count-issue.patch \
               "
SRCREV ="f2da78deb3a105c7270f74d9d747c77f0feaae2c"

