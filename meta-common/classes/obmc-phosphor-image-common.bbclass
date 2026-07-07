inherit obmc-phosphor-image
inherit license_static

IMAGE_FEATURES += " \
        obmc-bmc-state-mgmt \
        obmc-bmcweb \
        obmc-chassis-mgmt \
        obmc-devtools \
        obmc-fan-control \
        obmc-fan-mgmt \
        obmc-flash-mgmt \
        obmc-host-ctl \
        obmc-host-ipmi \
        obmc-inventory \
        obmc-leds \
        obmc-logging-mgmt \
        obmc-remote-logging-mgmt \
        obmc-net-ipmi \
        obmc-sensors \
        obmc-software \
        obmc-system-mgmt \
        obmc-user-mgmt \
        ${@bb.utils.contains('DISTRO_FEATURES', 'obmc-ubi-fs', 'read-only-rootfs', '', d)} \
        ${@bb.utils.contains('DISTRO_FEATURES', 'phosphor-mmc', 'read-only-rootfs', '', d)} \
        ssh-server-dropbear \
        obmc-debug-collector \
        obmc-network-mgmt \
        obmc-settings-mgmt \
        obmc-console \
        "

IMAGE_INSTALL:append = " \
        dbus-broker \
        intel-ipmi-oem \
        smbios-mdr \
        system-watchdog \
        callback-manager \
        preinit-mounts \
        mtd-utils-ubifs \
        special-mode-mgr \
        ac-boot-check \
        psu-manager \
        kernel-panic-check \
        hsbp-manager \
        security-registers-check \
        nv-sync \
        security-manager \
        host-misc-comm-manager \
        telemetry \
        i3c-tools \
        zip \
	peci-pcie \
	libespi \
        "

IMAGE_INSTALL:remove:oks-features = " peci-pcie "

IMAGE_INSTALL:append:oks-features = " mctpd mctp-cmd-tool cxl-cci mmbi-ipmi "

#IMAGE_INSTALL:append:bhs-features = " \
#        power-feature-discovery \
#        "

IMAGE_INSTALL:append = " ${@bb.utils.contains('IMAGE_FSTYPES', 'intel-pfr', 'pfr-manager', '', d)}"
IMAGE_INSTALL:append = " ${@bb.utils.contains('IMAGE_FSTYPES', 'intel-pfr', 'secure-pfr-manager', '', d)}"

IMAGE_INSTALL:append = " ${@bb.utils.contains('IMAGE_FSTYPES', 'intel-pfr', 'ncsi-monitor', '', d)}"
IMAGE_INSTALL:append = " ${@bb.utils.contains('IMAGE_FSTYPES', 'intel-secboot', 'ncsi-monitor', '', d)}"

# this package was flagged as a security risk
IMAGE_INSTALL:remove = " lrzsz"

BAD_RECOMMENDATIONS += "phosphor-settings-manager"
