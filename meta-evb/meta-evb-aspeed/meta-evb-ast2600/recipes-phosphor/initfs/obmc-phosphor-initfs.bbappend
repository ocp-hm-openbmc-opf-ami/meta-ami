FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI:append = " file://init-options"

do_install:append() {
    install -m 0644 ${WORKDIR}/init-options ${D}/init-options
}