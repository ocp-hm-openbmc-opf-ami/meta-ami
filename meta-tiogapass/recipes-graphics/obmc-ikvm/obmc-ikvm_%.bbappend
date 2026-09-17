FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI:append = " \
	file://0001-create_usbhid-support-AST2500.patch \
	file://0002-tiogapass-use-full-JPEG-frames.patch \
"