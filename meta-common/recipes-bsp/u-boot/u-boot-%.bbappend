FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI += " \
    file://fw_env.config \
    file://CVE-2019-14200.patch \
    "
