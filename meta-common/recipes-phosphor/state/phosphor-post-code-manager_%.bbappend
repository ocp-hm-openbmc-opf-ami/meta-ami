FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"
SRC_URI += "git://git@github.com/ocp-hm-openbmc-opf-ami/phosphor-post-code-manager.git;branch=integrate-onetree-3.1.1;protocol=https;name=override;"
SRCREV_FORMAT = "override"
SRCREV_override = "96d8350a2e2f64a73efd1df2c0dc137d8ecb401d"

python () {
    if bb.utils.contains('EXTRA_IMAGE_FEATURES', 'onetree-multi-host-support', True, False, d) \
       and d.getVar('MULTI_HOST_DEFAULT_MODE') == '1':
        d.setVar('OBMC_HOST_INSTANCES', '1 2')
}
