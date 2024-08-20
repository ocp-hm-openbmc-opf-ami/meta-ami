FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI = "git://git.ami.com/core/ami-bmc/one-tree/core/libmctp.git;protocol=https;branch=LF-MCTP \
           file://default"
SRCREV = "b902035ad40ce28df390b139f1801babb6b3af29"

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
                         mctp-restart-notify.service \
                        "

CONFFILES:${PN} = "${datadir}/mctp/mctp"

FILES:${PN}:append = "${datadir} ${datadir}/mctp"

do_install:append() {
    install -d ${D}${datadir}/mctp
    if [ -e "${WORKDIR}/mctp-restart-notify.service" ]; then
        install -m 0644 ${WORKDIR}/mctp-restart-notify.service ${D}${nonarch_base_libdir}/systemd/system/mctp-restart-notify.service
    fi
}
