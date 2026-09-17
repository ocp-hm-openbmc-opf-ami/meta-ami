do_install:prepend() {
    install -d ${D}${datadir}/phosphor-led-manager
}

do_install:append() {
    # Rename the LED config to the expected filename.
    if [ -f ${D}${datadir}/phosphor-led-manager/led.json ]; then
        mv ${D}${datadir}/phosphor-led-manager/led.json \
           ${D}${datadir}/phosphor-led-manager/led-group-config.json
    fi
}
