SUMMARY = "Pendtask daemon"
DESCRIPTION = "Daemon implementing PEF retry alert interface for SMTP and SNMP alerts"
LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/files/common-licenses/Apache-2.0;md5=89aea4e17d99a7cacdbeed46a0096b10"

SRC_URI = "file://pendtask.cpp \
           file://pendtask.hpp \
           file://xyz.openbmc_project.Pendtask.Pef.service"

S = "${UNPACKDIR}"

CXXFLAGS:append = " -std=c++20"

DEPENDS += "phosphor-dbus-interfaces \
            sdbusplus \
            phosphor-logging \
            phosphor-snmp \
            nlohmann-json"

RDEPENDS:${PN} += "phosphor-snmp"

inherit pkgconfig systemd obmc-phosphor-dbus-service

# Register the systemd unit as the DBus service
DBUS_SERVICE:${PN} += "xyz.openbmc_project.Pendtask.Pef.service"
DBUS_PACKAGES = "${PN}"

SYSTEMD_SERVICE:${PN} = "xyz.openbmc_project.Pendtask.Pef.service"

do_compile() {
    ${CXX} ${CXXFLAGS} ${LDFLAGS} \
        pendtask.cpp -o pendtask \
        $(pkg-config --cflags --libs sdbusplus phosphor-dbus-interfaces phosphor-logging) \
        -lsnmp -lpthread
}

do_install() {
    # Install binary
    install -d ${D}${bindir}
    install -m 0755 pendtask ${D}${bindir}/

    # Install systemd unit file
    install -d ${D}${systemd_system_unitdir}
    install -m 0644 ${UNPACKDIR}/xyz.openbmc_project.Pendtask.Pef.service \
        ${D}${systemd_system_unitdir}/
}

FILES:${PN} += "${bindir}/pendtask \
                ${systemd_system_unitdir}/xyz.openbmc_project.Pendtask.Pef.service "
