FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"
SRC_URI:append = "file://0001-Commented-failsafe-mode.patch"


do_install:append() {
    # Remove the installed JSON file
    rm -f ${D}${datadir}/swampd/config.json
}

FILES:${PN}:append = " ${datadir}/swampd"

