SUMMARY = "HP PCI GOP scripts and firmware"
DESCRIPTION = "Install PCI configuration scripts and Option ROM firmware"
LICENSE = "CLOSED"

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI = " \
    file://pci_cfg.sh \
    file://check_setup.sh \
    file://OptionRom.rom \
    file://dpu_pci_scan \
"

S = "${UNPACKDIR}"

do_install() {

    install -d ${D}${bindir}
    install -m 0755 ${UNPACKDIR}/pci_cfg.sh ${D}${bindir}/
    install -m 0755 ${UNPACKDIR}/check_setup.sh ${D}${bindir}/
    install -m 0755 ${UNPACKDIR}/dpu_pci_scan ${D}${bindir}/

    install -d ${D}${nonarch_base_libdir}/firmware
    install -m 0644 ${UNPACKDIR}/OptionRom.rom ${D}${nonarch_base_libdir}/firmware/
}

FILES:${PN} += " \
    ${bindir}/pci_cfg.sh \
    ${bindir}/check_setup.sh \
    ${bindir}/dpu_pci_scan \
    ${nonarch_base_libdir}/firmware/OptionRom.rom \
"

RDEPENDS:${PN} += "libdrm"
