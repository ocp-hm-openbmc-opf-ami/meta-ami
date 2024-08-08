FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI += " file://channel_config.json \
             file://channel_access.json \
           "
           
