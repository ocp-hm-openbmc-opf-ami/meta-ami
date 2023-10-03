do_install:append() {
    #Rules to automatically start services for multiple TTY
    install -d ${D}${base_libdir}/udev/rules.d
    install -m 0644 ${S}/conf/80-obmc-console-uart.rules.in ${D}${base_libdir}/udev/rules.d/80-obmc-console-uart.rules
}

