SUMMARY = "Intel OEM IPMI commands"
DESCRIPTION = "Intel OEM IPMI commands"

LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://LICENSE;md5=a6a4edad4aed50f39a66d098d74b265b"

SRC_URI = "git://github.com/openbmc/intel-ipmi-oem;branch=master;protocol=https"
SRCREV = "ee27fe0973115e8b93a782fcdd956f468e99b107"

S = "${WORKDIR}/git"
PV = "0.1+git${SRCPV}"

DEPENDS = "boost phosphor-ipmi-host phosphor-logging systemd phosphor-dbus-interfaces libgpiod libtinyxml2"

inherit meson obmc-phosphor-ipmiprovider-symlink pkgconfig

LIBRARY_NAMES = "libzinteloemcmds.so"

HOSTIPMI_PROVIDER_LIBRARY += "${LIBRARY_NAMES}"
NETIPMI_PROVIDER_LIBRARY += "${LIBRARY_NAMES}"

FILES:${PN}:append = " ${libdir}/ipmid-providers/lib*${SOLIBS}"
FILES:${PN}:append = " ${libdir}/host-ipmid/lib*${SOLIBS}"
FILES:${PN}:append = " ${libdir}/net-ipmid/lib*${SOLIBS}"
FILES:${PN}-dev:append = " ${libdir}/ipmid-providers/lib*${SOLIBSDEV}"

# intel-ipmi-oem-ext is a drop-in replacement for the stock intel-ipmi-oem and
# ships the same libzinteloemcmds.so. Declare the replacement so the two are never
# installed together (which broke do_rootfs with an RPM file conflict) while still
# satisfying anything that RDEPENDS on intel-ipmi-oem (e.g. packagegroup-intel-apps).
RPROVIDES:${PN} += "intel-ipmi-oem"
RREPLACES:${PN} += "intel-ipmi-oem"
RCONFLICTS:${PN} += "intel-ipmi-oem"

do_install:append(){
   install -d ${D}${includedir}/intel-ipmi-oem
   install -m 0644 -D ${S}/include/*.hpp ${D}${includedir}/intel-ipmi-oem
}
