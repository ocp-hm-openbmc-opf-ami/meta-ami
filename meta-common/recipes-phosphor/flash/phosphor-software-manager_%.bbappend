FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"


SRC_URI_NON_PFR:append = "file://0001-AMI-Combined-all-firmware-update-patches.patch \
                file://0004-pldm-bundle-raw-upload-and-activation-improvements.patch \
                file://0005-pldm-package-parser-libpldm-api-compat.patch \
                file://0006-Added-Parallel-FW-update-support.patch \
                file://0014-Run-deferred-image-deletes-on-main-async-context.patch \
   "

SRC_URI:append = " file://fwupdinband@.service \
         file://inband-fwupd.sh \
         file://0003-update-whitelist-file-based-on-user-selection-and-tr.patch \
      file://0004-Fix-startUpdate-signature-for-new-sdbusplus-server.patch \
         file://fwupd-reboot-decision.sh \
         file://0007-Compare_the_blacklist_and_whitelist_druing_factory_r.patch \
"

DEPENDS:append = " libpldm"
DEPENDS:remove = "${@bb.utils.contains('IMAGE_FEATURES', 'onetree-pldm', 'libpldm', '', d)}"
DEPENDS:append = "${@bb.utils.contains('IMAGE_FEATURES', 'onetree-pldm', ' ot-libpldm', '', d)}"

DEPENDS:remove = "${@bb.utils.contains('IMAGE_FEATURES', 'onetree-nvidiasipack', 'libpldm', '', d)}"
DEPENDS:append = "${@bb.utils.contains('IMAGE_FEATURES', 'onetree-nvidiasipack', ' pldm', '', d)}"

RDEPENDS:${PN}-updater:append = " libpldm"
RDEPENDS:${PN}-updater:remove = "${@bb.utils.contains('IMAGE_FEATURES', 'onetree-pldm', 'libpldm', '', d)}"
RDEPENDS:${PN}-updater:append = "${@bb.utils.contains('IMAGE_FEATURES', 'onetree-pldm', ' ot-libpldm', '', d)}"

RDEPENDS:${PN}-updater:remove = "${@bb.utils.contains('IMAGE_FEATURES', 'onetree-nvidiasipack', 'libpldm', '', d)}"
RDEPENDS:${PN}-updater:append = "${@bb.utils.contains('IMAGE_FEATURES', 'onetree-nvidiasipack', ' pldm', '', d)}"

# NVIDIA's libpldm still uses the original symbol name crc32()
# libpldm renamed it to pldm_edac_crc32() in 0004 patch via the PACKAGE_HEADER_CRC32 macro. 
CXXFLAGS:append = "${@bb.utils.contains('IMAGE_FEATURES', 'onetree-nvidiasipack', ' -Dpldm_edac_crc32=crc32', '', d)}"

SRC_URI:append = " \
   file://reboot-guard-enable.service \
   file://reboot-guard-disable.service \
"

EXTRA_OEMESON += "${@bb.utils.contains('BBFILE_COLLECTIONS', 'intel-features', ' -Dfwupd-intel-features=enabled','', d)}"
SRC_URI:append = " ${@bb.utils.contains('IMAGE_FSTYPES', 'intel-pfr', '', SRC_URI_NON_PFR, d)}"

PACKAGECONFIG:append = "${@bb.utils.contains('IMAGE_FEATURES', 'onetree-bios-update', ' flash_bios ','', d)}"
PACKAGECONFIG:append = "${@bb.utils.contains('IMAGE_FEATURES', 'onetree-image-sign', ' verify_signature ','', d)}"
PACKAGECONFIG:append = "${@bb.utils.contains('IMAGE_FEATURES', 'onetree-dual-image', ' static-dual-image ','', d)}"
PACKAGECONFIG:append = "${@bb.utils.contains('IMAGE_FEATURES', 'onetree-sync-conf', ' sync_bmc_files ','', d)}"

OPTIONAL_IMAGES = "image-bios,image-cpld,image-pldm,image-raid,image-psu,image-nvme"
EXTRA_OEMESON += "${@bb.utils.contains('IMAGE_FSTYPES', 'intel-pfr', '','-Dfwupd-script=enabled', d)}"
EXTRA_OEMESON += "${@bb.utils.contains('IMAGE_FSTYPES', 'intel-pfr', '','-Doptional-images=${OPTIONAL_IMAGES}', d)}"
EXTRA_OEMESON += "${@bb.utils.contains('PACKAGECONFIG', 'static-dual-image','-Dactive-bmc-max-allowed=3', '-Dactive-bmc-max-allowed=2', d)}"
EXTRA_OEMESON:append:intel-ast2600 = "${@bb.utils.contains('PACKAGECONFIG', 'sync_bmc_files',' -Dalt-rwfs-dir="/run/media/rwfs-alt/.overlay"', '', d)}"


SRC_URI_NON_PFR_DUAL:append = "file://intel-flash-bmc \
                                file://obmc-flash-bmc-static-mount-alt.service.in \
                                file://intel-flash-bmc-static-mount-alt.service.in \
                                file://ami-flash-bmc \
                                file://detect-slot-aspeed \
                                file://reset-cs0-aspeed  \
                                file://synclist \
                                file://0002-adding-support-for-non-pfr-dual-image-inventory-popu.patch \
                                "                          
SRC_URI_NON_PFR_DUAL:append:intel-ast2600 = " file://sync-once.sh \
                                             "

SRC_URI_NON_PFR_DUAL:append = " file://obmc-flash-bmc-prepare-for-sync.service.in \
                                          file://xyz.openbmc_project.Software.Sync.service.in \
                                file://xyz.openbmc_project.Software.Sync.service.d/10-conditional.conf \
                                              "

SRC_URI:append = " ${@bb.utils.contains('PACKAGECONFIG', 'static-dual-image', SRC_URI_NON_PFR_DUAL , '', d)}"
FILES:${PN}-updater:append:intel-ast2600 = "${@bb.utils.contains('PACKAGECONFIG', 'static-dual-image', ' ${bindir}/intel-flash-bmc ', '', d)}" 
FILES:${PN}-updater:append = "${@bb.utils.contains('PACKAGECONFIG', 'static-dual-image', ' ${bindir}/ami-flash-bmc', '', d) if d.getVar('MACHINE') in ['evb-ast2600', 'ast2700-default', 'ast2700-a1-spl'] else ''}"
FILES:${PN}-updater:append:intel-ast2600 = "${@bb.utils.contains('PACKAGECONFIG', 'static-dual-image', ' ${systemd_unitdir}/system/obmc-flash-bmc-static-mount-alt.service ', '', d)}" 
FILES:${PN}-updater:append = "${@bb.utils.contains('PACKAGECONFIG', 'static-dual-image', ' ${bindir}/detect-slot-aspeed ', '', d)}" 
FILES:${PN}-updater:append = "${@bb.utils.contains('PACKAGECONFIG', 'static-dual-image', ' ${bindir}/reset-cs0-aspeed ', '', d)}" 
FILES:${PN}-updater:append = "${@bb.utils.contains('PACKAGECONFIG', 'sync_bmc_files', ' ${bindir}/sync-once.sh ', '', d)}" 
FILES:${PN}-updater:append = "${@bb.utils.contains('PACKAGECONFIG', 'sync_bmc_files', ' /etc/sync-enable ', '', d)}"
FILES:${PN}-updater:append = "${@bb.utils.contains('PACKAGECONFIG', 'sync_bmc_files', ' ${systemd_unitdir}/system/xyz.openbmc_project.Software.Sync.service.d/10-conditional.conf ', '', d)}"
FILES:${PN}-updater:append = "${bindir}/inband-fwupd.sh"
FILES:${PN}-updater:append = " ${bindir}/fwupd-reboot-decision.sh"
FILES:${PN}-updater:append = " ${libexecdir}/phosphor-code-mgmt/pldm-bundle-extraction-tool"
# pldm-bundle-extraction-tool is built directly from bmc/pldm_bundle_tool.cpp in the source tree

do_install:append () {
      install -m 0755 ${UNPACKDIR}/inband-fwupd.sh ${D}${bindir}/inband-fwupd.sh
   install -m 0755 ${UNPACKDIR}/fwupd-reboot-decision.sh ${D}${bindir}/fwupd-reboot-decision.sh
      install -m 0644 ${UNPACKDIR}/fwupdinband@.service ${D}${systemd_unitdir}/system/fwupd@.service
   install -m 0644 ${UNPACKDIR}/reboot-guard-enable.service ${D}${systemd_unitdir}/system/reboot-guard-enable.service
   install -m 0644 ${UNPACKDIR}/reboot-guard-disable.service ${D}${systemd_unitdir}/system/reboot-guard-disable.service
      if ${@bb.utils.contains('IMAGE_FSTYPES', 'intel-pfr', 'false', 'true', d)}; then
         if ${@bb.utils.contains('PACKAGECONFIG','static-dual-image','true','false',d)}; then
            install -m 0755 ${UNPACKDIR}/detect-slot-aspeed ${D}${bindir}/detect-slot-aspeed
            if ${@bb.utils.contains('PACKAGECONFIG','sync_bmc_files','true','false',d)}; then
               install -m 0755 ${UNPACKDIR}/synclist ${D}/etc/synclist
               install -m 0644 ${UNPACKDIR}/obmc-flash-bmc-prepare-for-sync.service.in  ${D}${systemd_unitdir}/system/obmc-flash-bmc-prepare-for-sync.service
               install -m 0644 ${UNPACKDIR}/xyz.openbmc_project.Software.Sync.service.in  ${D}${systemd_unitdir}/system/xyz.openbmc_project.Software.Sync.service	
               install -d ${D}${systemd_unitdir}/system/xyz.openbmc_project.Software.Sync.service.d
               install -m 0644 ${UNPACKDIR}/xyz.openbmc_project.Software.Sync.service.d/10-conditional.conf ${D}${systemd_unitdir}/system/xyz.openbmc_project.Software.Sync.service.d/10-conditional.conf
               touch ${D}/etc/sync-enable
            fi
	
         fi  
      fi
}

do_install:append:intel-ast2600 () {
   if ${@bb.utils.contains('PACKAGECONFIG','static-dual-image','true','false',d)}; then
        install -m 0644 ${UNPACKDIR}/intel-flash-bmc-static-mount-alt.service.in  ${D}${systemd_unitdir}/system/obmc-flash-bmc-static-mount-alt.service
        install -m 0755 ${UNPACKDIR}/intel-flash-bmc ${D}${bindir}/intel-flash-bmc
        if ${@bb.utils.contains('PACKAGECONFIG','sync_bmc_files','true','false',d)}; then
           install -m 0755 ${UNPACKDIR}/sync-once.sh ${D}${bindir}/sync-once.sh
        fi
   fi
}

do_install:append() {
   case "${MACHINE}" in evb-ast2600|ast2700-default|ast2700-a1-spl)
      if ${@bb.utils.contains('PACKAGECONFIG','static-dual-image','true','false',d)}; then
         install -m 0644 ${UNPACKDIR}/obmc-flash-bmc-static-mount-alt.service.in  ${D}${systemd_unitdir}/system/obmc-flash-bmc-static-mount-alt.service
         install -m 0755 ${UNPACKDIR}/ami-flash-bmc ${D}${bindir}/ami-flash-bmc
         install -m 0755 ${UNPACKDIR}/detect-slot-aspeed ${D}${bindir}/reset-cs0-aspeed
      fi
   ;;
   esac
}

# Disable Manager mode and force legacy Updater service
EXTRA_OEMESON:append = " -Dsoftware-update-dbus-interface=disabled"

# Explicit D-Bus service assignments for legacy mode
DBUS_SERVICE:${PN}-version = "xyz.openbmc_project.Software.Version.service"
DBUS_SERVICE:${PN}-updater = "xyz.openbmc_project.Software.BMC.Updater.service"

PACKAGECONFIG[software-update-dbus-interface] = ""
