FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"                                                                                                                                                                   


SRC_URI += " \
           file://ntpsec.conf \
           file://ntpsec-ca-certificates.crt \
           "
RDEPENDS:${PN}-viz = ""

REQUIRED_DISTRO_FEATURES:remove = "x11"

PACKAGECONFIG = " nts refclocks ${@bb.utils.filter('DISTRO_FEATURES', 'systemd', d)}"

PACKAGE_BEFORE_PN:remove = "${PN}-viz"
SYSTEMD_PACKAGES:remove = "${PN}-viz"
SYSTEMD_SERVICE:${PN}:remove = "ntp-wait.service"
SYSTEMD_SERVICE:${PN}-viz = ""

SYSTEMD_AUTO_ENABLE:${PN} = "disable"

do_install:append(){

  rm -rf ${D}/etc/ntp.d

  install -d ${D}/etc
  install -d ${D}/etc/ntpsec

  install -m 0644 -D ${UNPACKDIR}/ntpsec.conf ${D}/etc/ntp.conf
  install -m 0644 -D ${UNPACKDIR}/ntpsec-ca-certificates.crt ${D}/etc/ntpsec/ntpsec-ca-certificates.crt

  rm -f ${D}${bindir}/ntpviz
  rm -f ${D}${bindir}/ntplogtemp
  rm -f ${D}${systemd_system_unitdir}/ntpviz-*.service
  rm -f ${D}${systemd_system_unitdir}/ntpviz-*.timer
  rm -f ${D}${systemd_system_unitdir}/ntplogtemp.*
  rm -f ${D}${systemd_system_unitdir}/ntp-wait.service       

}

