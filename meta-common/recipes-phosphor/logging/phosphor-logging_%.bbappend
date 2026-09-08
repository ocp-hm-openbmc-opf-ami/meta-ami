FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"


SRC_URI = "git://git@github.com/ocp-hm-openbmc-opf-ami/phosphor-logging.git;branch=integrate-onetree-3.1.1;protocol=https;name=override;"
SRCREV_FORMAT = "override"
SRCREV_override = "0131c91986674c183b87466c635375ef1a897200"

EXTRA_OEMESON:append = " -Derror_cap=350 -Derror_info_cap=900 -Dstorage-select=emmc_sdcard"
