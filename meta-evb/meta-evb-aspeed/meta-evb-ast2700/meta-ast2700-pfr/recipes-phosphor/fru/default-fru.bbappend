FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI:append:ast2700-dcscm-sdk-features = " \
   file://decodeBoardID.sh;subdir=${BP} \
   "
