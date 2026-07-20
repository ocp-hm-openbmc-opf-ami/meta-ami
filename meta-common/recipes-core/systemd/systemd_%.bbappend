FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

DEBUG_PREFIX_MAP:remove = "-fmacro-prefix-map=${S}=${TARGET_DBGSRC_DIR}"

SRC_URI += "file://0001-Support-DHCPv6-Transmission-Retransmission-Timing-Parameters.patch \
	    file://0002-Fix-to-update-DHCPv6-address-in-systemd-file.patch \
	    file://0003-updated-to-fallback-ntp-servers.patch \
	    file://0004-Ensured-timezone-settings-after-firmware-update.patch \
	    file://0005-Preserved-NTP-setting-after-Restore-Factory-Default.patch \
            file://0006-Fixed-the-timeSync-preserve-settings-when-NTP-is-disabled.patch \
        file://0005-Fix-to-reduce-systemd-networkd-wait-online.service-t.patch \
        file://0007-Handle-NTPSec-mode-separately-in-timedated-persist.patch \
        file://journald.conf \
	file://CVE-2026-40226.patch \
        file://serial-getty-nolimit.conf"

do_install:append() {
    install -d ${D}${sysconfdir}/systemd
    install -m 0644 ${UNPACKDIR}/journald.conf ${D}${sysconfdir}/systemd/

    # Install a drop-in to disable the restart rate limit for serial-getty.
    # Setting StartLimitIntervalSec=0 disables the rate limit so serial-getty
    # always recovers automatically without requiring a BMC reboot.
    install -d ${D}${sysconfdir}/systemd/system/serial-getty@.service.d
    install -m 0644 ${UNPACKDIR}/serial-getty-nolimit.conf \
        ${D}${sysconfdir}/systemd/system/serial-getty@.service.d/nolimit.conf
}
