# Restricted override ami-fw-update script

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"
PROJECT_SRC_DIR := "${THISDIR}/files"
LICENSE = "Proprietary"
LIC_FILES_CHKSUM = "file://${AMIBASE}/COPYING.AMI;md5=65a69a674f34a9f30737c9f0abd4fc5c"

SRC_URI = " \
    file://gen_fwupd.py \
    file://fwupd.json \
    file://common.sh \
    file://applyonreset.sh \
    file://apply-onreset.service \
    file://clearboot.sh \
    file://clearboot-system-shutdown \
    file://usb-ctrl \
    file://prepare-bmc.sh \
    file://flash-bmc.sh \
    file://flash-compbmc.sh \
    file://cleanup-bmc.sh \
    file://flash-bios.sh \
    file://flash-cpld.sh \
    file://flash-pldm.sh \
    file://flash-raid.sh \
    file://fwupd_singlespiabr.json\
    file://flash-nvme.sh \"

inherit allarch
inherit systemd
inherit obmc-phosphor-systemd
# Runtime dependencies. Adjust to your distro’s packaging for these tools.
RDEPENDS:${PN} += " \
    bash \
    systemd \
    mtd-utils \
    busybox \
    dropbear \
    dosfstools \
    dtc \
    dbus-tools \
    coreutils-stdbuf \
"
SYSTEMD_PACKAGES = "${PN}"
SYSTEMD_SERVICE:${PN} = "apply-onreset.service"

S = "${WORKDIR}/git"
B = "${WORKDIR}/build"

do_compile() {
    install -d ${B}
    
    # Use fwupd_singlespiabr.json when onetree-single-spi-abr feature is enabled
    if ${@bb.utils.contains('IMAGE_FEATURES', 'onetree-single-spi-abr', 'true', 'false', d)}; then
        cp ${UNPACKDIR}/fwupd_singlespiabr.json ${UNPACKDIR}/fwupd.json
    fi
    
    python3 ${UNPACKDIR}/gen_fwupd.py \
        --json ${UNPACKDIR}/fwupd.json \
        --out  ${B}/fwupd.sh
    chmod 0755 ${B}/fwupd.sh
}

do_install() {

    # /usr/libexec/fwupd for all helpers
    install -d ${D}${libexecdir}/fwupd

    # Common runtime library
    install -m 0755 ${UNPACKDIR}/common.sh ${D}${libexecdir}/fwupd/common.sh

    # Component scripts: install if present
    for f in \
        prepare-bmc.sh flash-bmc.sh flash-compbmc.sh cleanup-bmc.sh \
        prepare-bios.sh flash-bios.sh cleanup-bios.sh \
        prepare-cpld.sh flash-cpld.sh cleanup-cpld.sh \
        prepare-pldm.sh flash-pldm.sh cleanup-pldm.sh \
        prepare-raid.sh flash-raid.sh cleanup-raid.sh \
        prepare-nvme.sh flash-nvme.sh cleanup-nvme.sh
    do
        if [ -f "${UNPACKDIR}/$f" ]; then
            install -m 0755 "${UNPACKDIR}/$f" "${D}${libexecdir}/fwupd/$f"
        fi
    done

    # Install the generated fwupd.sh into /usr/bin
    install -d ${D}${bindir}
    install -m 0755 ${B}/fwupd.sh ${D}${bindir}/fwupd.sh

    # Install usb-ctrl only when phosphor-misc-usb-ctrl is NOT present in image
    if ${@bb.utils.contains('OBMC_IMAGE_EXTRA_INSTALL','phosphor-misc-usb-ctrl','false','true',d)}; then
        install -m 0755 ${UNPACKDIR}/usb-ctrl ${D}${bindir}/usb-ctrl
    fi

    install -m 0755 ${UNPACKDIR}/applyonreset.sh ${D}${bindir}/applyonreset.sh
    install -m 0755 ${UNPACKDIR}/clearboot.sh ${D}${bindir}/clearboot.sh

    # Install fwupd.json configuration
    install -d ${D}/etc
    if ${@bb.utils.contains('IMAGE_FEATURES', 'onetree-single-spi-abr', 'true', 'false', d)}; then
        install -m 0644 ${UNPACKDIR}/fwupd_singlespiabr.json ${D}/etc/fwupd.json
    else
        install -m 0644 ${UNPACKDIR}/fwupd.json ${D}/etc/fwupd.json
    fi

    # Run clearboot at the very end of shutdown/reboot, after services stop.
    install -d ${D}${nonarch_base_libdir}/systemd/system-shutdown
    install -m 0755 ${UNPACKDIR}/clearboot-system-shutdown \
        ${D}${nonarch_base_libdir}/systemd/system-shutdown/clearboot

    # systemd unit
    install -d ${D}${systemd_system_unitdir}
    install -m 0644 ${UNPACKDIR}/apply-onreset.service \
        ${D}${systemd_system_unitdir}/apply-onreset.service

}

# Not strictly required, but explicit is fine:
FILES:${PN} += " \
    ${bindir}/fwupd.sh \
    ${bindir}/applyonreset.sh \
    ${bindir}/clearboot.sh \
    ${bindir}/usb-ctrl \
    ${libexecdir}/fwupd/* \
    ${systemd_system_unitdir}/apply-onreset.service \
    ${nonarch_base_libdir}/systemd/system-shutdown/clearboot \
    /etc/fwupd.json \
"
