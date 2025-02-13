FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

include ${@bb.utils.contains('EXTRA_IMAGE_FEATURES', 'use-lfmctp', 'spdmd_lfmctp.inc', '', d)}

