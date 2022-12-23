FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"
PROJECT_SRC_DIR := "${THISDIR}/${PN}"

SRC_URI += "\
    file://0007-add-pef.patch \
    file://0008-linear_sel_policy_support.patch \
"

DEPENDS += "intel-ipmi-oem"
RDEPENDS:${PN} += "intel-ipmi-oem"

