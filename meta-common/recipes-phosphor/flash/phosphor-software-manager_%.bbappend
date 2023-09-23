FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI_NON_PFR:append = "file://0001-Add-Purpose-for-other-components-and-add-image-mtd-s.patch \
                   file://0002-populate-cpld-inventory-with-version-on-bootup.patch \
                   file://0004-Add-write-public-key-in-image-support.patch \
                   file://fwupdinband@.service "

SRC_URI:append = " ${@bb.utils.contains('IMAGE_FSTYPES', 'intel-pfr', '', SRC_URI_NON_PFR, d)}"

PACKAGECONFIG:append = "${@bb.utils.contains('IMAGE_FSTYPES', 'intel-pfr', '','flash_bios', d)}"
PACKAGECONFIG:append = "${@bb.utils.contains('IMAGE_FSTYPES', 'intel-pfr', '',' verify_signature ', d)}"
PACKAGECONFIG:append = "${@bb.utils.contains('EXTRA_IMAGE_FEATURES', 'dual-image', ' static-dual-image ','', d)}"
EXTRA_OEMESON += "${@bb.utils.contains('IMAGE_FSTYPES', 'intel-pfr', '','-Dfwupd-script=enabled', d)}"
EXTRA_OEMESON += "${@bb.utils.contains('IMAGE_FSTYPES', 'intel-pfr', '','-Doptional-images=image-bios,image-cpld', d)}"
EXTRA_OEMESON += "${@bb.utils.contains('IMAGE_FSTYPES', 'intel-pfr', '','-Dactive-bmc-max-allowed=2', d)}"

SRC_URI_NON_PFR_DUAL:append = "file://intel-flash-bmc \
                                file://obmc-flash-bmc-static-mount-alt.service.in \
                                file://0003-adding-support-for-non-pfr-dual-image-inventory-popu.patch "

SRC_URI:append = " ${@bb.utils.contains('PACKAGECONFIG', 'static-dual-image', SRC_URI_NON_PFR_DUAL , '', d)}"
FILES:${PN}-updater:append:intel-ast2600 = "${@bb.utils.contains('PACKAGECONFIG', 'static-dual-image', ' ${bindir}/intel-flash-bmc ', '', d)}" 
FILES:${PN}-updater:append:intel-ast2600 = "${@bb.utils.contains('PACKAGECONFIG', 'static-dual-image', ' ${systemd_unitdir}/system/obmc-flash-bmc-static-mount-alt.service ', '', d)}" 

do_install:append:intel-ast2600 () {
   if ${@bb.utils.contains('IMAGE_FSTYPES', 'intel-pfr', 'false', 'true', d)}; then
         install -m 0644 ${WORKDIR}/fwupdinband@.service ${D}${systemd_unitdir}/system/fwupd@.service
   fi
   if ${@bb.utils.contains('PACKAGECONFIG','static-dual-image','true','false',d)}; then
        install -m 0644 ${WORKDIR}/obmc-flash-bmc-static-mount-alt.service.in  ${D}${systemd_unitdir}/system/obmc-flash-bmc-static-mount-alt.service
        install -m 0755 ${WORKDIR}/intel-flash-bmc ${D}${bindir}/intel-flash-bmc
   fi
}


