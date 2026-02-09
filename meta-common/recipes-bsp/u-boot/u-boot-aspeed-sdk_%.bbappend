FILESEXTRAPATHS:append:intel-ast2600:= "${THISDIR}/files:"

SRC_URI:append:intel-ast2600 = " \
    file://00016-U-Boot-Disable-unused-zlib-functionality.patch \
    file://CVE-2019-14200.patch \
    file://CVE-2019-14194.patch \
    file://CVE-2019-14195.patch \
    file://CVE-2019-14196.patch \
    file://CVE-2022-30767.patch \
    file://CVE-2020-8432.patch \
    file://CVE-2022-2347.patch \
    "
