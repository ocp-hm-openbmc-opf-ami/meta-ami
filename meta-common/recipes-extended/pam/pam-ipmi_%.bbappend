FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI += " \
    file://0038-ipmi_pass-File-Validation.patch  \
    file://0001-Fix-for-Resource-leak.patch  \
    "
python Add_DefaultUser_if_debugtweaks_not_enabled() {
    if 'allow-root-login' not in d.getVar('EXTRA_IMAGE_FEATURES', True).split():
        d.appendVar('SRC_URI', " file://ipmi_pass_32;subdir=git/")
}
