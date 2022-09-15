SUMMARY = "Intel ACD application"
SECTION = "examples"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI += "file://CMakeLists.txt"
SRC_URI += "file://crashdump.cpp"
SRC_URI += "file://crashdump.hpp"
SRC_URI += "file://utils_dbusplus.cpp"
SRC_URI += "file://utils_dbusplus.hpp"
SRC_URI += "file://CrashdumpSections/"
SRC_URI += "file://IntelACD.service"
SRC_URI += "file://crashdump_input_spr.json"

DEPENDS = "boost sdbusplus linux-aspeed systemd cjson safec libpeci"
#RDEPENDS_${PN} = "libpeci"
S = "${WORKDIR}"

inherit cmake systemd pkgconfig 
EXTRA_OECMAKE += "-DYOCTO_DEPENDENCIES=ON"
TARGET_CXXFLAGS += " -I ${STAGING_KERNEL_DIR}/include/uapi"
TARGET_CXXFLAGS += " -I ${STAGING_KERNEL_DIR}/include/"
CFLAGS += " -I ${STAGING_KERNEL_DIR}/include/uapi"
CFLAGS += " -I ${STAGING_KERNEL_DIR}/include/"

SYSTEMD_SERVICE_${PN} = "IntelACD.service"


do_install() {
         install -d ${D}${bindir}
         install -m 0755 crashdump ${D}${bindir}
	 install -m 0755 -d ${D}/usr/share/crashdump
	 install -m 0755 -d ${D}/usr/share/crashdump/input
	 install -d ${D}${sysconfdir}/systemd/system
         install -m 0644 ${S}/IntelACD.service ${D}${sysconfdir}/systemd/system/
	 install -m 0755 ${S}/crashdump_input_spr.json  ${D}/usr/share/crashdump/input/
}
FILES:${PN} += "/usr/bin/"
FILES:${PN} += "${sysconfdir}/systemd/system/*"
FILES:${PN} += "/usr/share/crashdump/input/*"
