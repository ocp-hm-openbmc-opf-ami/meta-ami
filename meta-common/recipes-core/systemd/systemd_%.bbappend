FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

DEBUG_PREFIX_MAP:remove = "-fmacro-prefix-map=${S}=${TARGET_DBGSRC_DIR}"

SRC_URI += "file://0001-Support-DHCPv6-Transmission-Retransmission-Timing-Parameters.patch \
	    file://0002-Fix-to-update-DHCPv6-address-in-systemd-file.patch \
	    file://0003-updated-to-fallback-ntp-servers.patch \
	    file://0004-Ensured-timezone-settings-after-firmware-update.patch \
            file://journald.conf"

do_install:append() {
    install -d ${D}${sysconfdir}/systemd
    install -m 0644 ${WORKDIR}/journald.conf ${D}${sysconfdir}/systemd/
}
