FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"



EXTRA_OECONF += "${@bb.utils.contains_any("IMAGE_FEATURES", [ 'debug-tweaks', 'allow-root-login' ], '', '--disable-root_user_mgmt', d)}"

SRC_URI += " \
             file://0003-Add-Host-Interface-User-Support.patch \
	     file://0012-passwordpolicy.patch \
	     file://0015-passwordchangerequired.patch \
             file://0017-SSH-Active-User-Delete-Fix.patch \
             file://0018-Added-group-user-for-host-interface.patch \
             file://0019-manual-lockout-fix.patch \
           "

FILES:${PN} += "${datadir}/dbus-1/system.d/phosphor-nslcd-cert-config.conf"
FILES:${PN} += "/usr/share/phosphor-certificate-manager/nslcd"
FILES:${PN} += "\
    /lib/systemd/system/multi-user.target.wants/phosphor-certificate-manager@nslcd.service"

