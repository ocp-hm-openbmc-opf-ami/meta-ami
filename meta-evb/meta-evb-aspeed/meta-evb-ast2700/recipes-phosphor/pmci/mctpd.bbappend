FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI:append = " \
    file://mctp_pcie_busowner.json \
    file://mctp_pcie_endpoint.json \
    file://0001-disable-all-warnings-being-treated-as-errors.patch \
    file://0002-smbus-add-to-check-root-device-map.patch \
    file://0003-add-tx-retry-mechanism-in-transmitqueuedmessages.patch \
    file://0004-support-cpp-20.patch \
"

do_install:append() {
     install -d ${D}/usr/share/mctp
     install -m 0664 ${WORKDIR}/*.json ${D}/usr/share/mctp
}

FILES:${PN} += "/usr/share/mctp/mctp_pcie_busowner.json"
FILES:${PN} += "/usr/share/mctp/mctp_pcie_endpoint.json"
