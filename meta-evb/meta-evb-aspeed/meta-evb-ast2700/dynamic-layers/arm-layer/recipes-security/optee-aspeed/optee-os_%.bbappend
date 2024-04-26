require optee-os-helper.inc

do_install:append() {
    # install core in firmware
    install -m 644 ${B}/core/tee.dmp ${D}${nonarch_base_libdir}/firmware/
    install -m 644 ${B}/core/tee.map ${D}${nonarch_base_libdir}/firmware/
}
