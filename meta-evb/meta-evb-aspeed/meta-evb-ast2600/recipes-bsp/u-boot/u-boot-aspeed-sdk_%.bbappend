FILESEXTRAPATHS:append := "${THISDIR}/files:"

COMPATIBLE_MACHINE = "evb-ast2600"

SRC_URI:append:emmc-sw-ami = " \
	file://emmc-support.cfg  \
	"
