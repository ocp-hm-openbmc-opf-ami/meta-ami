FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"
SRC_URI += "git://git@github.com/ocp-hm-openbmc-opf-ami/phosphor-post-code-manager.git;branch=integrate-onetree-latest;protocol=https;name=override;"
SRCREV_FORMAT = "override"
SRCREV_override = "8fbd66a504c673203666d2f7d66c76142cf7e299"

python () {
    if bb.utils.contains('EXTRA_IMAGE_FEATURES', 'onetree-multi-host-support', True, False, d) \
       and d.getVar('MULTI_HOST_DEFAULT_MODE') == '1':
        d.setVar('OBMC_HOST_INSTANCES', '1 2')
}
