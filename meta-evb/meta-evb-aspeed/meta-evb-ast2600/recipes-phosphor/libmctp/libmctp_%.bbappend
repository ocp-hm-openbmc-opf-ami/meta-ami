FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

# Workaround for string truncation warning
TARGET_CFLAGS:append = " -Wno-error=stringop-truncation"

RDEPENDS:${PN} += " bash udev"

inherit obmc-phosphor-dbus-service obmc-phosphor-systemd

#PACKAGECONFIG_append_pn-systemd = " --disable-mctp-spi-ctrl"
#remove settings in PACKAGECONFIG
#PACKAGECONFIG ??= "${@bb.utils.filter('DISTRO_FEATURES', 'systemd', d)} pcap"
PACKAGECONFIG[systemd] = ""
PACKAGECONFIG[pcap] = ""

PACKAGECONFIG:append = "${@bb.utils.contains('ENABLE_MCTP_KERNEL_MODE', '1', ' libmctp-kernel-mode', '', d)}"

SRC_URI:append: = " \
                file://systemd/start_mctp.sh \
                file://systemd/cpu-boot-complete.sh \
                file://systemd/check_failed_host_boot.sh \
                file://systemd/perst_udev_event.sh \
   "
   
SRC_URI:append = "${@bb.utils.contains('ENABLE_MCTP_KERNEL_MODE', '1', 'file://mctp_cfg_kernel.cfg ', 'file://mctp_cfg_smbus8.json ', d)}"
SRC_URI:append = "${@bb.utils.contains('ENABLE_MCTP_KERNEL_MODE', '1', 'file://systemd/mctp-kernel-ctrl.service ', 'file://systemd/mctp-i2c8-ctrl.service file://systemd/mctp-i2c8-demux.service file://systemd/mctp-i2c8-demux.socket', d)}"

SYSTEMD_SERVICE:${PN}:remove:evb-ast2600 = " mctp-spi-ctrl.service "
SYSTEMD_SERVICE:${PN}:remove:evb-ast2600 = " mctp-spi-demux.service "
SYSTEMD_SERVICE:${PN}:remove:evb-ast2600 = " mctp-spi-demux.socket "
SYSTEMD_SERVICE:${PN}:remove:evb-ast2600 = " mctp-pcie-ctrl.service "
SYSTEMD_SERVICE:${PN}:remove:evb-ast2600 = " mctp-pcie-demux.service "
SYSTEMD_SERVICE:${PN}:remove:evb-ast2600 = " mctp-pcie-demux.socket "
SYSTEMD_SERVICE:${PN}:append:evb-ast2600 = "${@bb.utils.contains('ENABLE_MCTP_KERNEL_MODE', '1', 'mctp-kernel-ctrl.service', 'mctp-i2c8-ctrl.service mctp-i2c8-demux.service mctp-i2c8-demux.socket', d)}"

# GraceBMC - all just clones of skinnyjoe for now
do_install:append:evb-ast2600() {
    install -d ${D}${datadir}/mctp
#    install -m 0644 ${S}/skinnyjoe/mctp ${D}${datadir}/mctp/mctp

    # We are not using the mctp-ctrl.service.d files, so clear them out
    rm -rf ${D}${nonarch_base_libdir}/systemd/system/mctp-ctrl.service.d    

    # In order to keep out changes limited to meta-gh, we are replaceing 
    # systemd files here.
    # This *should* be upstreamed when we are comfortable with these changes...
    rm -f ${D}${nonarch_base_libdir}/systemd/system/mctp-pcie-ctrl.service
    rm -f ${D}${nonarch_base_libdir}/systemd/system/mctp-pcie-demux.service
    rm -f ${D}${nonarch_base_libdir}/systemd/system/mctp-pcie-demux.socket
#
   # We are not starting the daemon directly, but through a script so the service
    # can restart the mctp controller 
    install -m 0755 ${UNPACKDIR}/systemd/start_mctp.sh ${D}${bindir}/
    install -m 0755 ${UNPACKDIR}/systemd/cpu-boot-complete.sh ${D}${bindir}/
    install -m 0755 ${UNPACKDIR}/systemd/check_failed_host_boot.sh ${D}${bindir}/
    install -m 0755 ${UNPACKDIR}/systemd/perst_udev_event.sh ${D}${bindir}/

    rm -f ${D}${nonarch_base_libdir}/systemd/system/mctp-spi-ctrl.service
    rm -f ${D}${nonarch_base_libdir}/systemd/system/mctp-spi-demux.service
    rm -f ${D}${nonarch_base_libdir}/systemd/system/mctp-spi-demux.socket
    
    if ${@bb.utils.contains('ENABLE_MCTP_KERNEL_MODE', '1', 'true', 'false', d)}; then
 	    install -m 0644 ${UNPACKDIR}/mctp_cfg_kernel.cfg ${D}${datadir}/mctp/mctp_cfg_kernel.cfg
	    install -m 0644 ${UNPACKDIR}/systemd/mctp-kernel-ctrl.service  ${D}${nonarch_base_libdir}/systemd/system/    
    else
	    install -m 0644 ${UNPACKDIR}/mctp_cfg_smbus8.json ${D}${datadir}/mctp/mctp_cfg_smbus8.json
	    install -m 0644 ${UNPACKDIR}/systemd/mctp-i2c8-ctrl.service  ${D}${nonarch_base_libdir}/systemd/system/
	    install -m 0644 ${UNPACKDIR}/systemd/mctp-i2c8-demux.service ${D}${nonarch_base_libdir}/systemd/system/
	    install -m 0644 ${UNPACKDIR}/systemd/mctp-i2c8-demux.socket  ${D}${nonarch_base_libdir}/systemd/system/
    fi
}
