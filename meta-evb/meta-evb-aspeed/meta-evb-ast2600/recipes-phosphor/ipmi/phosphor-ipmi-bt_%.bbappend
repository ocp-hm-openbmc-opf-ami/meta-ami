FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI:append = " file://org.openbmc.HostIpmi.service"

do_install:append() {
    # Overriding service
    install -d ${D}${systemd_system_unitdir}
    install -m 0644 ${WORKDIR}/org.openbmc.HostIpmi.service ${D}${systemd_system_unitdir}
}