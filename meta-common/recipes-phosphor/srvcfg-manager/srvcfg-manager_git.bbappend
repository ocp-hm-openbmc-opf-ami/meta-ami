FILESEXTRAPATHS:append := "${THISDIR}/${PN}:"

SRCREV = "d8effd63e885cb755aa44665d833b20f187c0e53"

SRC_URI += " \
           file://0001-Added-Virtualmedia-service-to-service-Config-Manager.patch \
           file://0002-Added-ipmb-service-to-service-Config-Manager.patch \
           "
