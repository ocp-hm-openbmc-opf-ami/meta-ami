FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"



EXTRA_OECONF += "${@bb.utils.contains_any("IMAGE_FEATURES", [ 'debug-tweaks', 'allow-root-login' ], '', '--disable-root_user_mgmt', d)}"

#OEM Privilege
PACKAGECONFIG:append ="${@bb.utils.contains('FEATURE_OEM_PRIV', '1', ' oem-privilege', ' ', d)}"
PACKAGECONFIG[oem-privilege] = "-Doem-privilege=enabled,-Doem-privilege=disabled"

SRCREV = "40419f91ea6d57fe618516231e56cda7db98725b"
SRC_URI += " \
             file://0003-Add-Host-Interface-User-Support.patch \
             file://0012-passwordpolicy.patch \
	     file://0015-passwordchangerequired.patch \
             file://0017-SSH-Active-User-Delete-Fix.patch \
             file://0018-Added-group-user-for-host-interface.patch \
             file://0019-manual-lockout-fix.patch \
             file://0020-add-media-group.patch \
           "

#OEM Privilege
SRC_URI_OEM_PRIV:append = "file://upgrade_media_group.sh \
             file://xyz.openbmc_project.User.Manager-ami.service \
                              "
SRC_URI:append = "${@bb.utils.contains('FEATURE_OEM_PRIV', '1',SRC_URI_OEM_PRIV, ' ', d)}"

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

EXTRA_USERS_PARAMS += "${@bb.utils.contains('FEATURE_OEM_PRIV', '1',OEM_PRIV_EXTRA_USERS_PARAMS, ' ', d)}"

