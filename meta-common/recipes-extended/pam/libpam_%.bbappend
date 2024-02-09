RDEPENDS:${PN}-runtime += "${MLPREFIX}pam-plugin-localuser-${libpam_suffix}"

FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI += " \
            file://faillock.conf \
            file://common-password-policy \
           "
do_install:append() {

rm -rf  ${D}${sysconfdir}/pam.d/common-password
cp ${WORKDIR}/common-password-policy ${D}${sysconfdir}/pam.d/common-password

}
