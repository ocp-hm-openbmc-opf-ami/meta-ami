SUMMARY = "nxp Computing LLC Host Control Implementation"
DESCRIPTION = "A host control implementation suitable for nxp Computing LLC's systems"
PR = "r1"
LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/Apache-2.0;md5=89aea4e17d99a7cacdbeed46a0096b10"

inherit systemd
inherit obmc-phosphor-systemd

RDEPENDS:${PN} = "bash"
S = "${UNPACKDIR}"

SRC_URI = " \
           file://host-poweroff@.service \
           file://host-poweron@.service \
           file://nxp-host-force-reset@.service \
           file://nxp_host_check.sh \
           file://host_reboot.sh \
           file://poweroff.sh \
           file://poweron.sh \
          "

SYSTEMD_PACKAGES = "${PN}"
SYSTEMD_SERVICE:${PN} = " host-poweron@.service \
                        host-poweroff@.service \
                         nxp-host-force-reset@.service \
                        "

# append force reboot
HOST_WARM_REBOOT_FORCE_TGT = "nxp-host-force-reset@.service"
HOST_WARM_REBOOT_FORCE_INSTMPL = "nxp-host-force-reset@{0}.service"
HOST_WARM_REBOOT_FORCE_TGTFMT = "obmc-host-force-warm-reboot@{0}.target"
HOST_WARM_REBOOT_FORCE_TARGET_FMT = "../${HOST_WARM_REBOOT_FORCE_TGT}:${HOST_WARM_REBOOT_FORCE_TGTFMT}.requires/${HOST_WARM_REBOOT_FORCE_INSTMPL}"
SYSTEMD_LINK:${PN} += "${@compose_list_zip(d, 'HOST_WARM_REBOOT_FORCE_TARGET_FMT', 'OBMC_HOST_INSTANCES')}"
SYSTEMD_SERVICE:${PN} += "${HOST_WARM_REBOOT_FORCE_TGT}"

HOST_POWER_ON_HOSTTMPL = "host-poweron@.service"
HOST_POWER_ON_HOSTINSTMPL = "host-poweron@{0}.service"
HOST_POWER_ON_HOSTTGTFMT = "obmc-host-startmin@{0}.target"
HOST_POWER_ON_HOSTFMT = "../${HOST_POWER_ON_HOSTTMPL}:${HOST_POWER_ON_HOSTTGTFMT}.requires/${HOST_POWER_ON_HOSTINSTMPL}"
SYSTEMD_LINK:${PN} += "${@compose_list_zip(d, 'HOST_POWER_ON_HOSTFMT', 'OBMC_HOST_INSTANCES')}"
SYSTEMD_SERVICE:${PN} += "${HOST_POWER_ON_HOSTTMPL}"

HOST_POWER_OFF_HOSTTMPL = "host-poweroff@.service"
HOST_POWER_OFF_HOSTINSTMPL = "host-poweroff@{0}.service"
HOST_POWER_OFF_HOSTTGTFMT = "obmc-host-shutdown@{0}.target"
HOST_POWER_OFF_HOSTFMT = "../${HOST_POWER_OFF_HOSTTMPL}:${HOST_POWER_OFF_HOSTTGTFMT}.requires/${HOST_POWER_OFF_HOSTINSTMPL}"
SYSTEMD_LINK:${PN} += "${@compose_list_zip(d, 'HOST_POWER_OFF_HOSTFMT', 'OBMC_HOST_INSTANCES')}"
SYSTEMD_SERVICE:${PN} += "${HOST_POWER_OFF_HOSTTMPL}"
do_install() {
    install -d ${D}/usr/sbin
    install -m 0755 ${UNPACKDIR}/nxp_host_check.sh ${D}/${sbindir}/
    install -m 0755 ${UNPACKDIR}/poweron.sh ${D}/${sbindir}/
    install -m 0755 ${UNPACKDIR}/poweroff.sh ${D}/${sbindir}/
    install -m 0755 ${UNPACKDIR}/host_reboot.sh ${D}/${sbindir}/
}
