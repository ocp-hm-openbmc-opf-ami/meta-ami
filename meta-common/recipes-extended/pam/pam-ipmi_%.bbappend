FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

python Add_DefaultUser_if_debugtweaks_not_enabled() {
    if 'debug-tweaks' not in d.getVar('EXTRA_IMAGE_FEATURES', True).split():
        d.appendVar('SRC_URI', " file://ipmi_pass_32;subdir=git/")
}
