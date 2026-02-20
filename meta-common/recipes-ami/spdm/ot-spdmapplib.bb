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
SRCREV = "733480786c87a042104636da238d5f9e36b09d31"

SRC_URI:oks-features = "git://git.ami.com/core/ami-bmc/one-tree/core/ot-spdmapplib.git;protocol=https;branch=oks"
SRCREV:oks-features = "5f09cc80078e9cd15e213dacb1165325a599e438"

SRC_URI:oks-features = "git://git.ami.com/core/ami-bmc/one-tree/core/ot-spdmapplib.git;protocol=https;branch=oks"
SRCREV:oks-features = "5f09cc80078e9cd15e213dacb1165325a599e438"

SRC_URI:append = " \
  file://sample_keys.tgz;subdir=./git \
"

SRC_URI:append = " \
    file://spdm-mctp-binding-cfg-ast2600evb.json \
    file://spdm-mctp-binding-cfg-egs.json \
    file://spdm-mctp-binding-cfg-bhs.json \
    file://spdm-mctp-binding-cfg-meta-mgx.json \
"

# Remove mctpwplus only when oks-features is NOT in OVERRIDES
DEPENDS:remove = "${@'' if 'oks-features' in d.getVar('OVERRIDES').split(':') else 'mctpwplus'}"

DEPENDS:append = " nlohmann-json cli11"
RDEPENDS:${PN}:append = " libmctp"

SPDM_BINDING_CFG = ""
SPDM_BINDING_CFG:append = "${@bb.utils.contains('BBFILE_COLLECTIONS', 'egs', 'spdm-mctp-binding-cfg-egs.json','',  d)}"
SPDM_BINDING_CFG:append = "${@bb.utils.contains('BBFILE_COLLECTIONS', 'bhs', 'spdm-mctp-binding-cfg-bhs.json','',  d)}"
SPDM_BINDING_CFG:append:evb-ast2600 = "${@bb.utils.contains('BBFILE_COLLECTIONS', 'evb-ast2600', 'spdm-mctp-binding-cfg-ast2600evb.json','',  d)}"
SPDM_BINDING_CFG:append = "${@bb.utils.contains('BBFILE_COLLECTIONS', 'meta-mgx', 'spdm-mctp-binding-cfg-meta-mgx.json','',  d)}"

do_install:append() {
    echo "SPDM_BINDING_CFG: ${SPDM_BINDING_CFG}"
    if [ ${SPDM_BINDING_CFG} != "" -a -f ${WORKDIR}/${SPDM_BINDING_CFG} ]; then
      install -m 0644 ${WORKDIR}/${SPDM_BINDING_CFG} ${D}${datadir}/spdmd/spdm-mctp-binding-cfg.json
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

