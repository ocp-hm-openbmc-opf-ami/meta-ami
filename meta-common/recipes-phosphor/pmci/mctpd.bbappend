FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI = "git://git.ami.com/core/ami-bmc/one-tree/core/firmware.bmc.openbmc.applications.mctpd.git;protocol=https;branch=openbmc/release/birchstream/common"
#SRCREV = "41ebd7abf42ef8fdfe4867f865c56063517edb6f"
#SRCREV = "aa25b313ea3358104c5836b0d1e2c240aada59fb"
SRCREV = "87279f7cb3313c56fdc419edeaf36251389ef265"
#SRC_URI += "file://0001-Add-secured-message-type-in-mctpd.patch"
