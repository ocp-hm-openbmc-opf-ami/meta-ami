FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"


SRC_URI = "git://git@github.com/ocp-hm-openbmc-opf-ami/phosphor-logging.git;branch=integrate-onetree-latest;protocol=https;name=override;"
SRCREV_FORMAT = "override"
SRCREV_override = "c9b60c48c8777468d571e952c83e0b6f375e181d"

EXTRA_OEMESON:append = " -Derror_cap=350 -Derror_info_cap=900 -Dstorage-select=emmc_sdcard"
