RDEPENDS:${PN}-runtime += "${MLPREFIX}pam-plugin-localuser-${libpam_suffix}"

FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI += "file://0001-pam-cracklib-passwordpolicy-update.patch \
            "


#Default settings lockout duration to 300 seconds and threshold value to 10
do_install:append() {
 sed -i 's/deny=0/deny=10/' ${D}${sysconfdir}/pam.d/common-auth
 sed -i 's/unlock_time=0/unlock_time=300/' ${D}${sysconfdir}/pam.d/common-auth
}
