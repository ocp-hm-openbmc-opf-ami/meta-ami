FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"



EXTRA_OECONF += "${@bb.utils.contains_any("IMAGE_FEATURES", [ 'debug-tweaks', 'allow-root-login' ], '', '--disable-root_user_mgmt', d)}"

#OEM Privilege
PACKAGECONFIG:append ="${@bb.utils.contains('FEATURE_OEM_PRIV', '1', ' oem-privilege', ' ', d)}"
PACKAGECONFIG[oem-privilege] = "-Doem-privilege=enabled,-Doem-privilege=disabled"

#SRCREV = "af1594c90627b78d1a92bb16a0d826b12a0d182c"
SRCREV = "e7d4559b0173596f29ceb5ba7da653b023067783"
SRC_URI += " \
             file://0003-Add-Host-Interface-User-Support.patch \
             file://0012-passwordpolicy.patch \
	     file://0015-passwordchangerequired.patch \
             file://0017-SSH-Active-User-Delete-Fix.patch \
             file://0019-manual-lockout-fix.patch \
             file://0016-Restricting-the-asd-user-under-redfish.patch \
             file://0018-add-snmp-media-group.patch \
             file://0022-Fix-to-add-support-to-include-dot-.-in-username.patch \
             file://0022-Added-chaanges-for-Pam-Reorder.patch \
             file://0025-OT-14429-Updated-username-validation-check.patch \
             file://0199-RadiusUserAccountService.patch \
             file://0023-KerberosRelatedUserManagerChanges.patch \
             file://0024-Kerberos-Config-User-Manager.patch \
             file://0202-IPV6-Feature-enable-related-changes.patch \
             file://0203-fixedInvalidPamreorder.patch \
             file://0204-Added-Radius-In-Pamorder.patch \
             file://0205-Removed-ipmi-Group-Check-Internal-Users.patch \
             file://0206-Rename-Sync-Snmp-User.patch \
           "
#OEM Privilege
SRC_URI_OEM_PRIV:append = "file://upgrade_media_group.sh \
                           file://xyz.openbmc_project.User.Manager-ami.service \
                          "

SYSTEMD_SERVICE:${PN} += " phosphor-kerberos-config.service"
SRC_URI:append = "${@bb.utils.contains('FEATURE_OEM_PRIV', '1',SRC_URI_OEM_PRIV, ' ', d)}"

FILES:${PN}  += "${systemd_system_unitdir}/phosphor-kerberos-config.service "
FILES:${PN} += "${datadir}/dbus-1/system.d/phosphor-nslcd-cert-config.conf"
FILES:${PN} += "/usr/share/phosphor-certificate-manager/nslcd"
FILES:${PN} += "\
    /lib/systemd/system/multi-user.target.wants/phosphor-certificate-manager@nslcd.service"

do_install:append () {
   if ${@bb.utils.contains('FEATURE_OEM_PRIV','1','true','false',d)}; then
        install -d ${D}${libexecdir}
        install -m 0755 ${WORKDIR}/upgrade_media_group.sh ${D}${libexecdir}/upgrade_media_group.sh
        install -m 0644 -D ${WORKDIR}/xyz.openbmc_project.User.Manager-ami.service ${D}${systemd_system_unitdir}/xyz.openbmc_project.User.Manager.service
   fi
}


OEM_PRIV_EXTRA_USERS_PARAMS =" \
   groupadd media; \
   usermod --append --groups media root; \
   "

GROUPADD_PARAM:${PN} = "${@bb.utils.contains('FEATURE_SNMP_TRAPV3', '1',"snmp" , ' ', d)}"

EXTRA_USERS_PARAMS += "${@bb.utils.contains('FEATURE_OEM_PRIV', '1',OEM_PRIV_EXTRA_USERS_PARAMS, ' ', d)}"

