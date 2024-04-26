SUMMARY = "aer-inject allows to inject PCIE AER errors in a running kernel"
DESCRIPTION = "aer-inject allows to inject PCIE AER errors on the software level into\
a running Linux kernel. This is intended for validation of the PCIE\
driver error recovery handler and PCIE AER core handler."

LICENSE = "GPL-2.0-only"
LIC_FILES_CHKSUM = "file://README;md5=95cd6a39bf9e2981abfc7c7cfaf5d6dd"
SRC_URI = "git://git.kernel.org/pub/scm/linux/kernel/git/gong.chen/aer-inject.git;branch=master"

DEPENDS = "bison-native"

PV = "1.0+git${SRCPV}"
SRCREV = "9bd5e2c7886fca72f139cd8402488a2235957d41"

S = "${WORKDIR}/git"

do_install() {
    oe_runmake "DESTDIR=${D}" "PREFIX=${bindir}" install
}
