#reset SRC_URI and assign branch to LFMCTP
SRC_URI = "git://git.ami.com/core/ami-bmc/one-tree/core/firmware.bmc.openbmc.libraries.spdmapplib.git;protocol=https;branch=LFMCTP"
SRCREV = "8238d401464fbd3ab90449fdd4a6210df3ea115f"

SRC_URI:append = " \
  file://sample_keys.tgz;subdir=./git \
"

SRC_URI:append = " \
    file://spdm-mctp-binding-cfg-ast2600evb.json \
    file://spdm-mctp-binding-cfg-egs.json \
    file://spdm-mctp-binding-cfg-bhs.json \
    file://spdm-mctp-binding-cfg-meta-mgx.json \
"


DEPENDS:remove = "${@bb.utils.contains('EXTRA_IMAGE_FEATURES', 'use-lfmctp', 'mctpwplus', '',  d)}"
DEPENDS:append = " nlohmann-json"
RDEPENDS:${PN}:append = "${@bb.utils.contains('EXTRA_IMAGE_FEATURES', 'use-lfmctp', ' libmctp', '',  d)}"

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
  ${datadir}/spdmd/spdm-mctp-binding-cfg.json \
"
