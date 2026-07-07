FILESEXTRAPATHS:append := "${THISDIR}/${PN}:"

SRC_URI += "file://2087-Coverity-Fix.patch  \
    file://2014-LDAP-AD-Auth-Init-Info.patch  \
    file://2015-Coverity-Fix.patch  \
    file://2016-Added-Coverity-Fix.patch \
    "

SYSTEMD_AUTO_ENABLE:${PN} = "disable"

