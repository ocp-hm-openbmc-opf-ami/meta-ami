FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

PACKAGECONFIG:append =  " gssapi"
EXTRA_OECONF:append = " --disable-digest "
