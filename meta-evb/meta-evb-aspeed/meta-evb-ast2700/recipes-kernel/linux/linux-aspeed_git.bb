KBRANCH = "aspeed-master-v6.6"
LINUX_VERSION ?= "6.6.1"

# Tag for v00.06.00
SRCREV = "db6d4731c26304858292ca2bd4803e59c05ad9c5"

LIC_FILES_CHKSUM = "file://COPYING;md5=6bc538ed5bd9a7fc9398086aedcd7e46"

require linux-aspeed.inc

DEPENDS += "lzop-native"
DEPENDS += "${@bb.utils.contains('MACHINE_FEATURES', 'ast-secure', 'aspeed-secure-config-native', '', d)}"

SRC_URI:append = " file://ipmi_ssif.cfg "
SRC_URI:append = " file://mtd_test.cfg "
SRC_URI:append = " file://crpyto_manager.cfg \
		   file://ipmb_dev.cfg \
		 "
SRC_URI:append = " file://nfs_cifs.cfg "
SRC_URI:append:cypress-s25hx = " file://jffs2_writebuffer.cfg "
