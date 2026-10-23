FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

DEPENDS += "nlohmann-json"
DEPENDS += "openssl"
DEPENDS += "libpam"
CXXFLAGS:append = " -I${STAGING_INCDIR}/nlohmann"
CXXFLAGS:append = " -I${STAGING_INCDIR}/openssl"
TARGET_LDFLAGS += "-lssl -lcrypto -lpam"

EXTRA_OECONF += "${@bb.utils.contains_any("IMAGE_FEATURES", [ 'debug-tweaks', 'allow-root-login' ], '', '--disable-root_user_mgmt', d)}"

#OEM Privilege
PACKAGECONFIG:append = "${@bb.utils.contains('FEATURE_OEM_PRIV', '1', ' oem-privilege', ' ', d)}"
PACKAGECONFIG[oem-privilege] = "-Doem-privilege=enabled,-Doem-privilege=disabled"

SRC_URI = "git://git.ami.com/core/ami-bmc/one-tree/core/phosphor-user-manager.git;branch=master;protocol=https"
SRCREV = "7dec724dd9691e43cea86071f5b69235d026ac99"

# Restore local file dropped by the hard SRC_URI assignment above; the base
# recipe's do_install:append installs it from UNPACKDIR.
SRC_URI += "file://upgrade_hostconsole_group.sh"

#OEM Privilege
SRC_URI_OEM_PRIV:append = " file://upgrade_media_group.sh \
                           file://xyz.openbmc_project.User.Manager-ami.service \
                          "
do_install:append () {
    install -m 0644 -D ${S}/phosphor-kerberos-config/phosphor-kerberos-config.service \
        ${D}${systemd_system_unitdir}/phosphor-kerberos-config.service
}
SRC_URI:append = "${@bb.utils.contains('FEATURE_OEM_PRIV', '1',SRC_URI_OEM_PRIV, ' ', d)}"

FILES:${PN}  += "${systemd_system_unitdir}/phosphor-kerberos-config.service "
FILES:${PN} += "${datadir}/dbus-1/system.d/phosphor-nslcd-cert-config.conf"
FILES:${PN} += "/usr/share/phosphor-certificate-manager/nslcd"
FILES:${PN} += "\
    /lib/systemd/system/multi-user.target.wants/phosphor-certificate-manager@nslcd.service"

do_install:append () {
   if ${@bb.utils.contains('FEATURE_OEM_PRIV','1','true','false',d)}; then
        install -d ${D}${libexecdir}
        install -m 0755 ${UNPACKDIR}/upgrade_media_group.sh ${D}${libexecdir}/upgrade_media_group.sh
        install -m 0644 -D ${UNPACKDIR}/xyz.openbmc_project.User.Manager-ami.service ${D}${systemd_system_unitdir}/xyz.openbmc_project.User.Manager.service
   fi
}


OEM_PRIV_EXTRA_USERS_PARAMS = " \
   groupadd media; \
   usermod --append --groups media root; \
   "

GROUPADD_PARAM:${PN}:append = "; ${@bb.utils.contains('FEATURE_SNMP_TRAPV3', '1',"snmp" , ' ', d)}"

EXTRA_USERS_PARAMS += "${@bb.utils.contains('FEATURE_OEM_PRIV', '1',OEM_PRIV_EXTRA_USERS_PARAMS, ' ', d)}"

