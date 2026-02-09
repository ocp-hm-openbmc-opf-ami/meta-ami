FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"


# The below patch moved to meta-ami
# so, not required to apply the below patches with meta-ami

SRC_URI_INTEL += " \
               file://0001-ADCSensor-Fix-for-P3V3-sensor.patch \
               "

SRC_URI:append = "${@bb.utils.contains('BBFILE_COLLECTIONS', 'meta-ami', '',SRC_URI_INTEL, d)}"


