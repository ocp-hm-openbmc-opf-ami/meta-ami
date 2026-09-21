DESCRIPTION = "Indentify if bmc boot is caused by AC power loss"
PR = "r1"
PV = "0.1"

LICENSE = "CLOSED"

SRC_URI = "file://bmc-boot-check.sh \
           "

SRC_URI_NON_PFR_HW_FAILSAFE_BOOT:append = " file://bmc-alternateboot-check.sh \
					    file://bmc-alternateboot-check_ast2700.sh \
                                            "

SRC_URI:append = "${@bb.utils.contains('IMAGE_FEATURES', 'onetree-hw-failsafe-boot', SRC_URI_NON_PFR_HW_FAILSAFE_BOOT,'', d)}"

inherit systemd
inherit obmc-phosphor-systemd

DEPENDS = "systemd"
RDEPENDS:${PN} = "bash"

SYSTEMD_PACKAGES = "${PN}"
do_install() {
    install -d ${D}/${bindir}
    install -m 0755 ${UNPACKDIR}/bmc-boot-check.sh ${D}/${bindir}/
}

do_install:append() {
    if ${@bb.utils.contains('IMAGE_FEATURES', 'onetree-hw-failsafe-boot', 'true', 'false', d)}; then
#Dual Image for At2700
       if [ "${MACHINE}" = "ast2700-default" ] || [ "${MACHINE}" = "ast2700-a1-spl" ]; then
        	install -m 0755 ${UNPACKDIR}/bmc-alternateboot-check_ast2700.sh ${D}/${bindir}/bmc-alternateboot-check.sh
    	else
        	install -m 0755 ${UNPACKDIR}/bmc-alternateboot-check.sh ${D}/${bindir}/
    	fi

    fi
}

SYSTEMD_SERVICE:${PN} = "xyz.openbmc_project.bmcbootcheck.service"
SYSTEMD_SERVICE:${PN}:append = " ${@bb.utils.contains('IMAGE_FEATURES', 'onetree-hw-failsafe-boot', \
                                               'xyz.openbmc_project.alternatebootcheck.service', \
                                               '', d)}"

