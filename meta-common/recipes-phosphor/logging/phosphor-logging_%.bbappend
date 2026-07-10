FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

EXTRA_OEMESON:append = " -Derror_cap=350 -Derror_info_cap=900 -Dstorage-select=emmc_sdcard"

SRCREV = "a3d1334ab06e5e380e1f9fccdbdba39fc73643eb"
