FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI:append = " file://obmc-init-ast2700.sh \
                               file://obmc-update-ast2700.sh \
                               file://obmc-shutdown.sh \
                               file://init-options \
                             "

do_install:append() {
    install -m 0755 ${WORKDIR}/obmc-init-ast2700.sh ${D}/init
    install -m 0755 ${WORKDIR}/obmc-update-ast2700.sh ${D}/update
    install -m 0644 ${WORKDIR}/init-options ${D}/init-options
}

# Update obmc-init.sh and obmc-update.sh for AST2700 single flash ABR.
SRC_URI:append:ast2700-abr = " file://obmc-init-ast2700-ABR.sh \
                               file://obmc-update-ast2700-ABR.sh \
                             "

do_install:append:ast2700-abr() {
    install -m 0755 ${WORKDIR}/obmc-init-ast2700-ABR.sh ${D}/init
    install -m 0755 ${WORKDIR}/obmc-update-ast2700-ABR.sh ${D}/update
}
