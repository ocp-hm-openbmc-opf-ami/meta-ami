FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"


SRC_URI = "git://git.ami.com/core/ami-bmc/one-tree/core/phosphor-logging.git;branch=master;protocol=https;name=override;"
SRCREV_FORMAT = "override"
SRCREV_override = "a3d1334ab06e5e380e1f9fccdbdba39fc73643eb"

EXTRA_OEMESON:append = " -Derror_cap=350 -Derror_info_cap=900 -Dstorage-select=emmc_sdcard"
