FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"
SRC_URI += "\
               file://0001-fix-bootcount-increment.patch \
               file://0002-MSFT-Phosphor-Post-Code-Manager-Intergration.patch \
               file://0003-throw-error-if-max-boot-cycle-exceeded.patch \
               file://0004-Ensure-proper-sequencing-of-PostCode-logs.patch \
               file://0005-Fixed-Postcode-Boot-count-issue.patch \
               "
SRCREV = "6b76468ad06c18686646c940999ccf20fe2e951c"

python () {
    if bb.utils.contains('EXTRA_IMAGE_FEATURES', 'onetree-multi-host-support', True, False, d) \
       and d.getVar('MULTI_HOST_DEFAULT_MODE') == '1':
        d.setVar('OBMC_HOST_INSTANCES', '1 2')
}
