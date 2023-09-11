FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"


SRC_URI:append = " \
	     file://0001-Add-IP-Rule-Table-Name-and-ID-for-each-Interface.patch \
             "
