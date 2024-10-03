SUMMARY = "Cerberus PFR Package Group"

PR = "r1"

PACKAGE_ARCH = "${TUNE_PKGARCH}"

inherit packagegroup

PROVIDES = "${PACKAGES}"
RPROVIDES:${PN} = "${PACKAGES}"

PACKAGES = " \
    ${PN}-apps \
    "

SUMMARY:${PN}-apps = "Cerberus PFR App package"
RDEPENDS:${PN}-apps = " \
    cerberus-pfr-provision-image \
    cerberus-pfr-key-cancellation-image \
    cerberus-pfr-key-manifest-image \
    "

