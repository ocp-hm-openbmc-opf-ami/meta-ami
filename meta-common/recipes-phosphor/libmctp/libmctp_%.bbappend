FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI = "git://git@github.com/ocp-hm-openbmc-opf-ami/libmctp.git;protocol=https;branch=main \
           file://default"
SRCREV = "7263074629e002df954efea5ac43c862978ffeca"

PACKAGECONFIG ??= ""
PACKAGECONFIG[libmctp-kernel-mode] = " -Dmctp-in-kernel-enable=enabled "

inherit obmc-phosphor-dbus-service obmc-phosphor-systemd
inherit meson

DEPENDS += "json-c \
            i2c-tools \
           "
           
SYSTEMD_SERVICE:${PN} = "mctp-pcie-demux.service \
                         mctp-pcie-demux.socket \
                         mctp-pcie-ctrl.service \
                         mctp-spi-demux.socket \
                         mctp-spi-demux.service \
                         mctp-spi-ctrl.service \
                        "
SYSTEMD_SERVICE:${PN}:remove = "${@bb.utils.contains('ENABLE_MCTP_KERNEL_MODE', '1', 'mctp-pcie-demux.service mctp-pcie-demux.socket mctp-pcie-ctrl.service', '', d)}"

CONFFILES:${PN} = "${datadir}/mctp/mctp"

FILES:${PN}:append = "${datadir} ${datadir}/mctp"

do_install:append() {
    install -d ${D}${datadir}/mctp

#    if [ -e "${WORKDIR}/mctp-restart-notify.service" ]; then
#        install -m 0644 ${WORKDIR}/mctp-restart-notify.service ${D}${nonarch_base_libdir}/systemd/system/mctp-restart-notify.service
#    fi
}
