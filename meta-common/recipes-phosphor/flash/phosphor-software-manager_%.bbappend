FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI_NON_PFR:append = "file://0001-Add-Purpose-for-other-components-and-add-image-mtd-s.patch \
                   file://0004-Add-write-public-key-in-image-support.patch \
                   file://fwupdinband@.service \
		             file://0005-Add-support-to-applytime-property.patch \
		"

SRC_URI:append = " ${@bb.utils.contains('IMAGE_FSTYPES', 'intel-pfr', '', SRC_URI_NON_PFR, d)}"

PACKAGECONFIG:append = "${@bb.utils.contains('EXTRA_IMAGE_FEATURES', 'bios-update', ' flash_bios ','', d)}"
PACKAGECONFIG:append = "${@bb.utils.contains('EXTRA_IMAGE_FEATURES', 'image-sign', ' verify_signature ','', d)}"
PACKAGECONFIG:append = "${@bb.utils.contains('EXTRA_IMAGE_FEATURES', 'dual-image', ' static-dual-image ','', d)}"
PACKAGECONFIG:append = "${@bb.utils.contains('EXTRA_IMAGE_FEATURES', 'sync-conf', ' sync_bmc_files ','', d)}"

EXTRA_OEMESON += "${@bb.utils.contains('IMAGE_FSTYPES', 'intel-pfr', '','-Dfwupd-script=enabled', d)}"
EXTRA_OEMESON += "${@bb.utils.contains('IMAGE_FSTYPES', 'intel-pfr', '','-Doptional-images=image-bios,image-cpld,image-pldm', d)}"
EXTRA_OEMESON += "${@bb.utils.contains('PACKAGECONFIG', 'static-dual-image','-Dactive-bmc-max-allowed=2', '', d)}"
EXTRA_OEMESON:append:intel-ast2600= "${@bb.utils.contains('PACKAGECONFIG', 'sync_bmc_files',' -Dalt-rwfs-dir="/run/media/rwfs-alt/.overlay"', '', d)}"

SRC_URI_NON_PFR_DUAL:append = "file://intel-flash-bmc \
                                file://obmc-flash-bmc-static-mount-alt.service.in \
                                file://intel-flash-bmc-static-mount-alt.service.in \
                                file://0003-adding-support-for-non-pfr-dual-image-inventory-popu.patch \
                                file://ami-flash-bmc \
                                file://detect-slot-aspeed \
                                file://reset-cs0-aspeed  \
                                "
SRC_URI_NON_PFR_DUAL:append = "${@bb.utils.contains('PACKAGECONFIG', 'verify_signature','file://0005-Patch-to-remove-the-image-when-verification-fails-nonpfr.patch', '', d)}"                              
SRC_URI_NON_PFR_DUAL:append:intel-ast2600 = " file://sync-once.sh \
                                             file://synclist "

SRC_URI:append = " ${@bb.utils.contains('PACKAGECONFIG', 'static-dual-image', SRC_URI_NON_PFR_DUAL , '', d)}"
FILES:${PN}-updater:append:intel-ast2600 = "${@bb.utils.contains('PACKAGECONFIG', 'static-dual-image', ' ${bindir}/intel-flash-bmc ', '', d)}" 
FILES:${PN}-updater:append:evb-ast2600 = "${@bb.utils.contains('PACKAGECONFIG', 'static-dual-image', ' ${bindir}/ami-flash-bmc ', '', d)}" 
FILES:${PN}-updater:append:intel-ast2600 = "${@bb.utils.contains('PACKAGECONFIG', 'static-dual-image', ' ${systemd_unitdir}/system/obmc-flash-bmc-static-mount-alt.service ', '', d)}" 
FILES:${PN}-updater:append = "${@bb.utils.contains('PACKAGECONFIG', 'static-dual-image', ' ${bindir}/detect-slot-aspeed ', '', d)}" 
FILES:${PN}-updater:append = "${@bb.utils.contains('PACKAGECONFIG', 'static-dual-image', ' ${bindir}/reset-cs0-aspeed ', '', d)}" 
FILES:${PN}-updater:append = "${@bb.utils.contains('PACKAGECONFIG', 'static-dual-image', ' ${bindir}/sync-once.sh ', '', d)}" 

do_install:append () {
      if ${@bb.utils.contains('IMAGE_FSTYPES', 'intel-pfr', 'false', 'true', d)}; then
         install -m 0644 ${WORKDIR}/fwupdinband@.service ${D}${systemd_unitdir}/system/fwupd@.service
         if ${@bb.utils.contains('PACKAGECONFIG','static-dual-image','true','false',d)}; then
            install -m 0755 ${WORKDIR}/detect-slot-aspeed ${D}${bindir}/detect-slot-aspeed
         fi  
      fi
}

do_install:append:intel-ast2600 () {
   if ${@bb.utils.contains('PACKAGECONFIG','static-dual-image','true','false',d)}; then
        install -m 0644 ${WORKDIR}/intel-flash-bmc-static-mount-alt.service.in  ${D}${systemd_unitdir}/system/obmc-flash-bmc-static-mount-alt.service
        install -m 0755 ${WORKDIR}/intel-flash-bmc ${D}${bindir}/intel-flash-bmc
        install -m 0755 ${WORKDIR}/sync-once.sh ${D}${bindir}/sync-once.sh
        install -m 0755 ${WORKDIR}/synclist ${D}/etc/synclist
   fi
}

do_install:append:evb-ast2600() {
   if ${@bb.utils.contains('PACKAGECONFIG','static-dual-image','true','false',d)}; then
        install -m 0644 ${WORKDIR}/obmc-flash-bmc-static-mount-alt.service.in  ${D}${systemd_unitdir}/system/obmc-flash-bmc-static-mount-alt.service
        install -m 0755 ${WORKDIR}/ami-flash-bmc ${D}${bindir}/ami-flash-bmc
        install -m 0755 ${WORKDIR}/detect-slot-aspeed ${D}${bindir}/reset-cs0-aspeed
   fi
}


