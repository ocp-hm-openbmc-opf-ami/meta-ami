FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI:append = " \
	file://ast2700-dcscm.cfg \
	file://0001-Adjust-dcscm-flash-layout.patch \
"

