FILESEXTRAPATHS:prepend := "${THISDIR}/settings:"


SRC_URI += " \
           file://0001-Add-SEL-policy-chacher.patch \
           file://system-guid.sh \
           file://system-guid.service \
           file://0003-Enable-the-SOL-by-default.patch \
           file://0004-USB-Register-USB-DBus-Methods.patch \
           file://0005-Adding-systemlock-object-path-interface-and-systemlo.patch \
	       file://0006-Add-support-to-applytime-property.patch \
	       file://Add-pre-check-for-enable-power-saving-mode.patch \
           file://0007-Added-Dbus-object-path-interface-and-property-for-BM.patch \
           file://0008-Added-errorFalg-and-infoFlags-for-multiple-logTypes.patch \
           file://0009-Added-Dbus-Object-for-DCMI-Thermal-Limit.patch \
	   file://0010-sol-session-bond-ifc.patch \
	   file://0011-Added-additional-boot-override-properties.patch \
	   file://0012-Added-last-entryId-for-ipmi.patch \
	   file://0013-Add-ipmi-entry-count.patch \
"

SRC_URI_evb_aspeed:append =  " \
           file://0005-Add-Restriction-Mode-Interface.patch \
            "
SRC_URI:append = "${@bb.utils.contains('BBFILE_COLLECTIONS', 'evb-aspeed', SRC_URI_evb_aspeed, '', d)}"

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

