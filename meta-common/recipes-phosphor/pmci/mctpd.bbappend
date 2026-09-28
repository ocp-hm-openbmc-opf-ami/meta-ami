FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI:bhs-features = "git://git.ami.com/core/ami-bmc/one-tree/core/firmware.bmc.openbmc.applications.mctpd.git;protocol=https;branch=openbmc/release/birchstream/common"

SRCREV:bhs-features = "87279f7cb3313c56fdc419edeaf36251389ef265"

#SRC_URI += "file://0001-Add-secured-message-type-in-mctpd.patch"

SRC_URI:bhs-features  = " file://0003-Fix-for-LF-sync-MCTPD.patch "

SRC_URI:append:2700-dcscm-features = " \
    file://0001-2700-DCSCM-BHS-mctpd-changes.patch \
    "
