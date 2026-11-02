SUMMARY = "SPDM Application Library"
DESCRIPTION = "Library for SPDM applications"

LICENSE = "Proprietary"
LIC_FILES_CHKSUM = "file://${AMIBASE}/COPYING.AMI;md5=65a69a674f34a9f30737c9f0abd4fc5c"

inherit pkgconfig meson

DEPENDS += " systemd \
            phosphor-logging \
            phosphor-dbus-interfaces \
            boost \
            libspdm \
            "

S = "${WORKDIR}/git"
PV = "1.0+git${SRCPV}"

SRC_URI = "git://git.ami.com/core/ami-bmc/one-tree/core/ot-spdmapplib.git;protocol=https;branch=main"
SRCREV = "aa166f512c4876cb3c1bee0e9bd6be56503e4e5c"

SRC_URI:append = " \
  file://sample_keys.tgz;subdir=./git \
"

DEPENDS:remove = " mctpwplus "

DEPENDS:append = " nlohmann-json cli11"
RDEPENDS:${PN}:append = "${@bb.utils.contains('ENABLE_COMMUNITY_MCTP_KERNEL_MODE', '1', ' mctp', ' libmctp', d)}"

FILES:${PN} += " \
  ${datadir}/spdmd \ 
  ${datadir}/spdmd/sample_keys/rsa3072 \
  ${datadir}/spdmd/sample_keys/rsa3072/bundle_requester.certchain.der \
  ${datadir}/spdmd/sample_keys/rsa3072/end_requester.key \
"

EXTRA_OEMESON = " \
  -Dyocto_dep='enabled' \
  -Denable_debug=false \
"
EXTRA_OEMESON:remove:oks-features = " -Denable_debug=false"
EXTRA_OEMESON:append = "${@bb.utils.contains('ENABLE_COMMUNITY_MCTP_KERNEL_MODE', '1', ' -Dcommunity_mctp=true', '', d)}"

