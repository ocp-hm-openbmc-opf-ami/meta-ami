SUMMARY = "Application for updating GPIO values to D-Bus"
LICENSE = "CLOSED"
FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI += " \
    file://src/gpio_presence.hpp \
    file://src/gpio_presence.cpp \
    file://services/gpio-presence.service \
    file://meson.build \
"

inherit meson systemd pkgconfig

S = "${WORKDIR}"

DEPENDS += " \
    sdbusplus \
    phosphor-dbus-interfaces \
    phosphor-logging \
    sdeventplus \
    libgpiod \
    nlohmann-json \
    "
SYSTEMD_PACKAGES = "${PN}"

SYSTEMD_SERVICE:${PN} = "gpio-presence.service"

do_install (){
        install -d ${D}${bindir}
        install -m 0755 gpio-presence ${D}${bindir}
        install -d ${D}${systemd_unitdir}/system
        install -m 0644 ${WORKDIR}/services/gpio-presence.service ${D}${systemd_unitdir}/system/
}


