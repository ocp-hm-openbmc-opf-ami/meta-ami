LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SUMMARY = "Radius shared library"
SECTION = "Network"
LICENSE = "MIT"
SRC_URI = "\
            file://CMakeLists.txt \
            file://include/ \
	    file://src/ \
	    file://nss-pam-radiusd.service \	
          "

S = "${WORKDIR}"
inherit cmake systemd pkgconfig
EXTRA_OECMAKE = " "

FILES:${PN} += "${libdir}/*.so"
FILES_SOLIBSDEV = ""
INSANE_SKIP:${PN} += "dev-so"

DEPENDS += " \
    sdbusplus \
    boost \
    phosphor-logging \
    "

do_install() {
  install -d ${D}/${systemd_unitdir}/system
  install -m 0644 ${WORKDIR}/nss-pam-radiusd.service ${D}/${systemd_unitdir}/system
  
  install -d ${D}${bindir}
  install -m 0755 ${B}/nss_pam_radius ${D}${bindir}

  install -d ${D}${libdir}
  install -m 0755 ${B}/libnss_radius.so ${D}${libdir}/libnss_radius.so.2
  install -m 0755 ${B}/libnss_radius.so ${D}${libdir}/
}

SYSTEMD_SERVICE:${PN} = "nss-pam-radiusd.service"
FILES:${PN} += "${systemd_unitdir}/system/nss-pam-radiusd.service"
FILES:${PN} += "${libdir}/libnss_radius.so.2"
FILES:${PN} += "${libdir}/libnss_radius.so"

