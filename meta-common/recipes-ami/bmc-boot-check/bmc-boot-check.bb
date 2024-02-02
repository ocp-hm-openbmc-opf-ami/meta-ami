DESCRIPTION = "Indentify if bmc boot is caused by AC power loss"
PR = "r1"
PV = "0.1"

LICENSE = "CLOSED"

SRC_URI = "file://bmc-boot-check.sh \
           "

SRC_URI_NON_PFR_HW_FAILSAFE_BOOT:append = " file://bmc-alternateboot-check.sh \
                                            "

SRC_URI:append:intel-ast2600 = "${@bb.utils.contains('EXTRA_IMAGE_FEATURES', 'hw-failsafe-boot', SRC_URI_NON_PFR_HW_FAILSAFE_BOOT,'', d)}"

inherit systemd
inherit obmc-phosphor-systemd

DEPENDS = "systemd"
RDEPENDS:${PN} = "bash"

SYSTEMD_PACKAGES = "${PN}"
do_install() {
    install -d ${D}/${bindir}
    install -m 0755 ${WORKDIR}/bmc-boot-check.sh ${D}/${bindir}/
}

do_install:append:intel-ast2600() {
    if ${@bb.utils.contains('EXTRA_IMAGE_FEATURES', 'hw-failsafe-boot', 'true', 'false', d)}; then
        install -m 0755 ${WORKDIR}/bmc-alternateboot-check.sh ${D}/${bindir}/
    fi
}

SYSTEMD_SERVICE:${PN} = "xyz.openbmc_project.bmcbootcheck.service"
SYSTEMD_SERVICE:${PN}:append:intel-ast2600 = " ${@bb.utils.contains('EXTRA_IMAGE_FEATURES', 'hw-failsafe-boot', \
                                               'xyz.openbmc_project.alternatebootcheck.service', \
                                               '', d)}"

