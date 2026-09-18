FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI:append:s997 = " file://10-s997-ordering.conf"

do_install:append:s997() {
    install -d ${D}${base_libdir}/systemd/system/phosphor-pid-control.service.d
    install -m 0644 ${UNPACKDIR}/10-s997-ordering.conf \
        ${D}${base_libdir}/systemd/system/phosphor-pid-control.service.d/10-s997-ordering.conf
}

FILES:${PN}:append:s997 = " ${base_libdir}/systemd/system/phosphor-pid-control.service.d"
