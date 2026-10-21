FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"


SRC_URI = "git://git.ami.com/core/ami-bmc/one-tree/core/phosphor-logging.git;branch=master;protocol=https;name=override;"
SRCREV_FORMAT = "override"
SRCREV_override = "0340f2da52a77eaf84feacad79ee0bc9bd22809d"

EXTRA_OEMESON:append = " -Derror_cap=350 -Derror_info_cap=900 -Dstorage-select=emmc_sdcard"
