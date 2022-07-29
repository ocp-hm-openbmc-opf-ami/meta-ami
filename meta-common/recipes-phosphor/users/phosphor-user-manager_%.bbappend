FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

# The URI is required for the autobump script but keep it commented
# to not override the upstream value
# SRC_URI = "git://github.com/openbmc/phosphor-user-manager;branch=master;protocol=https"
SRCREV = "2f64e4206e2e46a3c2ca4e19a5162f1df6fb97ea"

EXTRA_OECONF += "${@bb.utils.contains_any("IMAGE_FEATURES", [ 'debug-tweaks', 'allow-root-login' ], '', '--disable-root_user_mgmt', d)}"

SRC_URI += " \
	     file://0012-passwordpolicy.patch \
           "

FILES:${PN} += "${datadir}/dbus-1/system.d/phosphor-nslcd-cert-config.conf"
FILES:${PN} += "/usr/share/phosphor-certificate-manager/nslcd"
FILES:${PN} += "\
    /lib/systemd/system/multi-user.target.wants/phosphor-certificate-manager@nslcd.service"
