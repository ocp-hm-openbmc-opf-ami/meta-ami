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
SRCREV = "d45f66518ab1928ee986d304faa42c99d2a6dc1c"

OKS_BRANCH_KEY = "branch"
OKS_BRANCH_EQUAL = "="
OKS_BRANCH_VALUE = "oks"

SRC_URI:oks-features = "git://git.ami.com/core/ami-bmc/one-tree/core/ot-spdmapplib.git;protocol=https;${OKS_BRANCH_KEY}${OKS_BRANCH_EQUAL}${OKS_BRANCH_VALUE}"
SRCREV:oks-features = "5f09cc80078e9cd15e213dacb1165325a599e438"

SRC_URI:append = " \
  file://sample_keys.tgz;subdir=./git \
"

DEPENDS:remove = " mctpwplus "

DEPENDS:append = " nlohmann-json cli11"
RDEPENDS:${PN}:append = "${@bb.utils.contains('ENABLE_COMMUNITY_MCTP_KERNEL_MODE', '1', ' mctp', ' libmctp', d)}"

do_install:append() {
    echo "SPDM_BINDING_CFG: ${SPDM_BINDING_CFG}"
    if [ ${SPDM_BINDING_CFG} != "" -a -f ${UNPACKDIR}/${SPDM_BINDING_CFG} ]; then
      install -m 0644 ${UNPACKDIR}/${SPDM_BINDING_CFG} ${D}${datadir}/spdmd/spdm-mctp-binding-cfg.json
    fi
}

FILES:${PN} += " \
  ${datadir}/spdmd \ 
  ${datadir}/spdmd/sample_keys/rsa3072 \
  ${datadir}/spdmd/sample_keys/rsa3072/bundle_requester.certchain.der \
  ${datadir}/spdmd/sample_keys/rsa3072/end_requester.key \
  ${datadir}/spdmd/spdm-mctp-binding-cfg.json \
"

EXTRA_OEMESON = " \
  -Dyocto_dep='enabled' \
  -Denable_debug=false \
"
EXTRA_OEMESON:remove:oks-features = " -Denable_debug=false"
EXTRA_OEMESON:append = "${@bb.utils.contains('ENABLE_COMMUNITY_MCTP_KERNEL_MODE', '1', ' -Dcommunity_mctp=true', '', d)}"

