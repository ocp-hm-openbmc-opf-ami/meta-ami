FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"
PROJECT_SRC_DIR := "${THISDIR}/${PN}"

SRCREV_override = "34cda935caf7d9f95cb28417fe1707b3ed33f3fc"
SRC_URI += "git://git@github.com/ocp-hm-openbmc-opf-ami/phosphor-sel-logger.git;branch=integrate-onetree-3.1.1;protocol=https;name=override;"
SRCREV_FORMAT = "override"

EXTRA_OEMESON +=  "-Dsel-extended=true"
DEPENDS += "intel-ipmi-oem-ext"
RDEPENDS:${PN} += "intel-ipmi-oem-ext"

DEPENDS:intel-ast2600 += "intel-ipmi-oem"
RDEPENDS:${PN}:intel-ast2600 += "intel-ipmi-oem"
RDEPENDS:${PN}:intel-ast2600:remove = "intel-ipmi-oem-ext"

DEPENDS:intel-ast2700 += "intel-ipmi-oem"
RDEPENDS:${PN}:intel-ast2700 += "intel-ipmi-oem"
RDEPENDS:${PN}:intel-ast2700:remove = "intel-ipmi-oem-ext"

DEPENDS:ast2700-dcscm += "intel-ipmi-oem"
RDEPENDS:${PN}:ast2700-dcscm += "intel-ipmi-oem"
RDEPENDS:${PN}:ast2700-dcscm:remove = "intel-ipmi-oem-ext"

DEPENDS:evb-ast2600 += "intel-ipmi-oem"
RDEPENDS:${PN}:evb-ast2600 += "intel-ipmi-oem"
RDEPENDS:${PN}:evb-ast2600:remove = "intel-ipmi-oem-ext"

DEPENDS:ast2700-default += "intel-ipmi-oem"
RDEPENDS:${PN}:ast2700-default += "intel-ipmi-oem"
RDEPENDS:${PN}:ast2700-default:remove = "intel-ipmi-oem-ext"

PACKAGECONFIG[log-crash] = "-Dlog-crash=true,-Dlog-crash=false"
PACKAGECONFIG:append = " send-to-logger log-threshold log-crash"

EXTRA_OEMESON:append = "${@' -Dstatic-sensor-number=true' if d.getVar('STATIC_SENSOR_NUMBER_ENABLE') == '1' else ' -Dstatic-sensor-number=false'}"
