FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

#removing old SRCREV , latest SRCREV mentioned in openbmc-meta-intel 


SRC_URI += " \
           file://0015-Add-to-warm-reset.patch \
           file://0016-Postpone-To-Wait-Network-Service.patch \
           "
