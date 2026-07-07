FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI = "git://git.ami.com/core/ami-bmc/one-tree/core/libpeci.git;branch=main;protocol=https"

SRCREV = "c49bf0413a5ac854808b1b2e06b6d866e294a8ef"

SRC_URI += " \
        file://99-peci.rules \
"

do_install:append() {
    install -d ${D}${libdir}/udev/rules.d
    install -m 0644 ${UNPACKDIR}/99-peci.rules ${D}${libdir}/udev/rules.d
}

PACKAGECONFIG:append:intel = " dbus-raw-peci"
