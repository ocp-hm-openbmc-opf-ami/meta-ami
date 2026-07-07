
${PN}-software-extras:append= " phosphor-software-manager-sync "
PACKAGES:remove = "${PN}-webui"
RDEPENDS:${PN}-user-mgmt-ldap:append = " krb5 pam-krb5 krb5-user "
RDEPENDS:${PN}-dmtf-pmci:remove = "${@bb.utils.contains('IMAGE_FEATURES', 'onetree-pldm', 'pldm', '', d)}"
