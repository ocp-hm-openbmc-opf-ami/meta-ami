FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

DEFAULT_INSTANCE = "ttyS2"

SRC_URI:append = " \
	file://ttyS2.conf \
	"
