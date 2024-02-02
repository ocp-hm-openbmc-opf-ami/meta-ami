FILESEXTRAPATHS:prepend := "${THISDIR}/settings:"


SRC_URI += " \
           file://0001-Add-SEL-policy-chacher.patch \
           file://system-guid.sh \
           file://system-guid.service \
           file://0003-Enable-the-SOL-by-default.patch \
"

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

