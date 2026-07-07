SUMMARY = "PWMTACH test application"
SECTION = "apps"
LICENSE = "CLOSED"

APP_NAME = "pwmtachtool"
bindir = "/usr/bin"

SRC_URI = "git://github.com/openbmc/openbmc-tools;protocol=https;branch=master \
           file://0002-pwm-max-min-value-range.patch \
           file://0003-set-fan-speed-set-dutycycle.patch \
           file://0001-Mapping-pwm-tach-number-starting-from-0.patch \
           file://0004-pwmtachtool-dutycycle-is-giving-percentage-instead-o.patch \
           file://0005-build_fix_pwmtachtool.patch \
           "

SRCREV = "8355598fbe7a98ea1d96666157cbbf2459ba8908"

S = "${WORKDIR}/git/pwmtachtool/src"
PV = "0.1+git${SRCPV}"

do_compile() {
     ${CC} pwmtachtool.c pwmtach.c  EINTR_wrappers.c ${LDFLAGS} -o pwmtachtool

}

do_install () {
    install -d ${D}${bindir}
    install -m 0755 -d ${D}${bindir}
    cd ${S}
    install -m 0755 ${APP_NAME} ${D}${bindir}
}

FILES_${PN}-dev = ""
FILES_${PN} = "${bindir}/*"
