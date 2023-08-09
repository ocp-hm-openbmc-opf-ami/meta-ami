FILESEXTRAPATHS:prepend := "${THISDIR}/settings:"


SRC_URI += " \
           file://0001-Add-SEL-policy-chacher.patch \
           file://system-guid.sh \
           file://system-guid.service "

SRC_URI_NON_PFR = "file://0002-moving-cpld-inventory-for-non-pfr-to-software-manage.patch "
SRC_URI:append = " ${@bb.utils.contains('IMAGE_FSTYPES', 'intel-pfr', '', SRC_URI_NON_PFR, d)}"

RDEPENDS:${PN} = "bash"
inherit systemd
SYSTEMD_SERVICE:${PN} += "system-guid.service"



do_install:append () {

 install -m 0755 ${WORKDIR}/system-guid.sh ${D}/${bindir}/system-guid.sh
     install -d ${D}${base_libdir}/systemd/system
    install -m 0644 ${WORKDIR}/system-guid.service ${D}${base_libdir}/systemd/system/system-guid.service


}



FILES:${PN} = "${bindir}/*"
FILES:${PN}:append = " ${base_libdir}/systemd/system/system-guid.service"

