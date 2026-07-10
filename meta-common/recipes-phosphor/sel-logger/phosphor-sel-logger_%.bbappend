FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"
PROJECT_SRC_DIR := "${THISDIR}/${PN}"

SRCREV_override = "59a245b0c717361fb02e0e0e95e2b1d0cae8d732"
SRC_URI += "git://git.ami.com/core/ami-bmc/one-tree/core/phosphor-sel-logger.git;branch=master;protocol=https;name=override;"
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
