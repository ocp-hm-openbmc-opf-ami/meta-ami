FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"


do_install:append() {
    # Remove the installed JSON file
    rm -f ${D}${datadir}/swampd/config.json
}

FILES:${PN}:append = " ${datadir}/swampd"

