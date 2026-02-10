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
    file://usb-ctrl \
    file://prepare-bmc.sh \
    file://flash-bmc.sh \
    file://flash-compbmc.sh \
    file://cleanup-bmc.sh \
    file://flash-bios.sh \
    file://flash-cpld.sh \
    file://flash-pldm.sh \
    file://flash-raid.sh \
    file://applyonreset_ast2700.sh \
    file://fwupd_singlespiabr.json\
"

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
"
SYSTEMD_PACKAGES = "${PN}"
SYSTEMD_SERVICE:${PN} = "apply-onreset.service"

S = "${WORKDIR}"
B = "${WORKDIR}/build"

do_compile() {
    install -d ${B}
    
    # Use fwupd_singlespiabr.json when onetree-single-spi-abr feature is enabled
    if ${@bb.utils.contains('IMAGE_FEATURES', 'onetree-single-spi-abr', 'true', 'false', d)}; then
        cp ${WORKDIR}/fwupd_singlespiabr.json ${WORKDIR}/fwupd.json
    fi
    
    python3 ${WORKDIR}/gen_fwupd.py \
        --json ${WORKDIR}/fwupd.json \
        --out  ${B}/fwupd.sh
    chmod 0755 ${B}/fwupd.sh
}

do_install() {

    # /usr/libexec/fwupd for all helpers
    install -d ${D}${libexecdir}/fwupd

    # Common runtime library
    install -m 0755 ${WORKDIR}/common.sh ${D}${libexecdir}/fwupd/common.sh

    # Component scripts: install if present
    for f in \
        prepare-bmc.sh flash-bmc.sh flash-compbmc.sh cleanup-bmc.sh \
        prepare-bios.sh flash-bios.sh cleanup-bios.sh \
        prepare-cpld.sh flash-cpld.sh cleanup-cpld.sh \
        prepare-pldm.sh flash-pldm.sh cleanup-pldm.sh \
        prepare-raid.sh flash-raid.sh cleanup-raid.sh
    do
        if [ -f "${WORKDIR}/$f" ]; then
            install -m 0755 "${WORKDIR}/$f" "${D}${libexecdir}/fwupd/$f"
        fi
    done

    # Install the generated fwupd.sh into /usr/bin
    install -d ${D}${bindir}
    install -m 0755 ${B}/fwupd.sh ${D}${bindir}/fwupd.sh

    # Install usb-ctrl only when phosphor-misc-usb-ctrl is NOT present in image
    if ${@bb.utils.contains('OBMC_IMAGE_EXTRA_INSTALL','phosphor-misc-usb-ctrl','false','true',d)}; then
        install -m 0755 ${WORKDIR}/usb-ctrl ${D}${bindir}/usb-ctrl
    fi
 
    #Dual Image for At2700	
    if [ "${MACHINE}" = "ast2700-default" ]; then
        install -m 0755 ${WORKDIR}/applyonreset_ast2700.sh ${D}${bindir}/applyonreset.sh
    else
        install -m 0755 ${WORKDIR}/applyonreset.sh ${D}${bindir}/applyonreset.sh
    fi
    # systemd unit
    install -d ${D}${systemd_system_unitdir}
    install -m 0644 ${WORKDIR}/apply-onreset.service \
        ${D}${systemd_system_unitdir}/apply-onreset.service
}

# Not strictly required, but explicit is fine:
FILES:${PN} += " \
    ${bindir}/fwupd.sh \
    ${bindir}/applyonreset.sh \
    ${bindir}/usb-ctrl \
    ${libexecdir}/fwupd/* \
    ${systemd_system_unitdir}/apply-onreset.service \
"
