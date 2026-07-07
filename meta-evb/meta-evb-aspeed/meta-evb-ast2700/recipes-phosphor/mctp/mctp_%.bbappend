FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI:append = " \
    "

do_install:append() {
#   install -m 755 ${WORKDIR}/build/mctp-req ${D}${bindir}
#   install -m 755 ${WORKDIR}/build/mctp-echo ${D}${bindir}
}
