FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

RDEPENDS:${PN} += " bash udev"

inherit obmc-phosphor-dbus-service obmc-phosphor-systemd

#PACKAGECONFIG_append_pn-systemd = " --disable-mctp-spi-ctrl"
#remove settings in PACKAGECONFIG
#PACKAGECONFIG ??= "${@bb.utils.filter('DISTRO_FEATURES', 'systemd', d)} pcap"
PACKAGECONFIG[systemd] = ""
PACKAGECONFIG[pcap] = ""

PRE_SRC_URI:append: = " \
                file://mctp_cfg_smbus8.json \
                file://systemd/mctp-i2c8-ctrl.service \
                file://systemd/mctp-i2c8-demux.service \
                file://systemd/mctp-i2c8-demux.socket \
                file://systemd/start_mctp.sh \
                file://systemd/cpu-boot-complete.sh \
                file://systemd/check_failed_host_boot.sh \
                file://systemd/perst_udev_event.sh \
   "

SYSTEMD_SERVICE:${PN}:remove:evb-npcm845 = " mctp-spi-ctrl.service "
SYSTEMD_SERVICE:${PN}:remove:evb-npcm845 = " mctp-spi-demux.service "
SYSTEMD_SERVICE:${PN}:remove:evb-npcm845 = " mctp-spi-demux.socket "
SYSTEMD_SERVICE:${PN}:remove:evb-npcm845 = " mctp-pcie-ctrl.service "
SYSTEMD_SERVICE:${PN}:remove:evb-npcm845 = " mctp-pcie-demux.service "
SYSTEMD_SERVICE:${PN}:remove:evb-npcm845 = " mctp-pcie-demux.socket "
#SYSTEMD_SERVICE:${PN}:append:evb-npcm845 = " mctp-i2c8-ctrl.service"
#SYSTEMD_SERVICE:${PN}:append:evb-npcm845 = " mctp-i2c8-demux.service"
#SYSTEMD_SERVICE:${PN}:append:evb-npcm845 = " mctp-i2c8-demux.socket"

# setup required files for evb-npcm845
do_install:append:evb-npcm845 () {
    install -d ${D}${datadir}/mctp

    # We are not using the mctp-ctrl.service.d files, so clear them out
    rm -rf ${D}${nonarch_base_libdir}/systemd/system/mctp-ctrl.service.d    

    # In order to keep out changes limited to meta-gh, we are replaceing 
    # systemd files here.
    # This *should* be upstreamed when we are comfortable with these changes...
    rm -f ${D}${nonarch_base_libdir}/systemd/system/mctp-pcie-ctrl.service
    rm -f ${D}${nonarch_base_libdir}/systemd/system/mctp-pcie-demux.service
    rm -f ${D}${nonarch_base_libdir}/systemd/system/mctp-pcie-demux.socket

    # We are not starting the daemon directly, but through a script so the service
    # can restart the mctp controller 
    #install -m 0755 ${WORKDIR}/systemd/start_mctp.sh ${D}${bindir}/
    #install -m 0755 ${WORKDIR}/systemd/cpu-boot-complete.sh ${D}${bindir}/
    #install -m 0755 ${WORKDIR}/systemd/check_failed_host_boot.sh ${D}${bindir}/
    #install -m 0755 ${WORKDIR}/systemd/perst_udev_event.sh ${D}${bindir}/
    #
    #install -m 0644 ${WORKDIR}/mctp_cfg_smbus8.json ${D}${datadir}/mctp/mctp_cfg_smbus8.json
    rm -f ${D}${nonarch_base_libdir}/systemd/system/mctp-spi-ctrl.service
    rm -f ${D}${nonarch_base_libdir}/systemd/system/mctp-spi-demux.service
    rm -f ${D}${nonarch_base_libdir}/systemd/system/mctp-spi-demux.socket
    #install -m 0644 ${WORKDIR}/systemd/mctp-i2c8-ctrl.service  ${D}${nonarch_base_libdir}/systemd/system/
    #install -m 0644 ${WORKDIR}/systemd/mctp-i2c8-demux.service ${D}${nonarch_base_libdir}/systemd/system/
    #install -m 0644 ${WORKDIR}/systemd/mctp-i2c8-demux.socket  ${D}${nonarch_base_libdir}/systemd/system/
}
