FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI_NON_PFR = "file://0001-Add-Purpose-for-other-components-and-add-image-mtd-s.patch"

SRC_URI:append = " ${@bb.utils.contains('IMAGE_FSTYPES', 'intel-pfr', '', SRC_URI_NON_PFR, d)}"

PACKAGECONFIG:append = "${@bb.utils.contains('IMAGE_FSTYPES', 'intel-pfr', '','flash_bios', d)}"
PACKAGECONFIG:append = "${@bb.utils.contains('IMAGE_FSTYPES', 'intel-pfr', '',' verify_signature ', d)}"
EXTRA_OEMESON += "${@bb.utils.contains('IMAGE_FSTYPES', 'intel-pfr', '','-Dfwupd-script=enabled', d)}"
EXTRA_OEMESON += "${@bb.utils.contains('IMAGE_FSTYPES', 'intel-pfr', '','-Doptional-images=image-bios,image-cpld', d)}"

