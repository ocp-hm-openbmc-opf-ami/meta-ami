FILESEXTRAPATHS:append := "${THISDIR}/${PN}:"

SRC_URI += "file://2087-Coverity-Fix.patch  \
    file://2014-LDAP-AD-Auth-Init-Info.patch  \
    file://2015-Coverity-Fix.patch  \
    file://2016-Added-Coverity-Fix.patch \
    file://2017-Reduced-Retry-Time.patch \
    file://2091-Coverity_Fix_LDAP_Oct.patch \
   "

SYSTEMD_AUTO_ENABLE:${PN} = "disable"

