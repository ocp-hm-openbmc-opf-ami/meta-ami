FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"


SRC_URI += " \
    file://0001-DefaultUser_admin_entry_added_ipmipass.patch \
    file://ipmi_pass_defaultusers;subdir=git/ \
    "
