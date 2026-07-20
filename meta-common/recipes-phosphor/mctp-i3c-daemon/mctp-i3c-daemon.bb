SUMMARY = "MCTP I3C Daemon Service"
DESCRIPTION = "Application to implement MCTP Over I3C Daemon "
LICENSE = "CLOSED"

SRC_URI = "file://mctp-i3c-main.cpp \
           file://mctp-netlink.cpp \
           file://mctp-log.cpp \
           file://utils.cpp \
           file://MctpDevice.cpp \
           file://mctp-encode.cpp \
           file://mctp-ctrl-cmds.cpp \
           file://include/mctp-netlink.hpp \
           file://include/mctp-app-log.hpp \
           file://include/mctp-ctrl-cmds.hpp \
           file://include/utils.hpp \
           file://include/MctpDevice.hpp \
           file://include/mctp-encode.hpp \
           file://include/mctp-i3c-client-sock.hpp \
           file://include/DebugFileMonitor.hpp \
           file://mctp-i3c-client-sock.cpp \
           file://meson_options.txt \
           file://meson.build \
           file://mctp-req.cpp \
           file://mctpctrl-cli-sock-test.cpp \
           file://mctp-i3c-daemon.service "

S = "${UNPACKDIR}"

CXXFLAGS:append = " -Os -ffunction-sections -fdata-sections -flto"

# Dependencies
DEPENDS = "systemd  json-c boost sdbusplus "

CXXFLAGS:append = " -Werror"

#EXTRA_OEMESON += "-Dclient-socket-interface='enabled' "

inherit pkgconfig systemd meson

# Ensure the systemd service file is recognized
SYSTEMD_SERVICE:${PN} = "mctp-i3c-daemon.service "

FILES:${PN} += "${datadir}/mctp"

# Install the binary
do_install() {

    install -d ${D}${bindir}
    install -d ${D}${datadir}/mctp

    install -m 0755 mctp-i3c-daemon ${D}${bindir}/mctp-i3c-daemon
    install -m 0755 mctp-req ${D}${bindir}/mctp-req
    install -m 0755 mctpctrl-cli-sock-test ${D}${bindir}/mctpctrl-cli-sock-test

    # Install the systemd service file
    install -d ${D}${systemd_system_unitdir}
    install -m 0644 ${UNPACKDIR}/mctp-i3c-daemon.service ${D}${systemd_system_unitdir}/mctp-i3c-daemon.service
}
