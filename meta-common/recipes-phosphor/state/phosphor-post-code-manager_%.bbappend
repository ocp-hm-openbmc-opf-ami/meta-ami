FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"
SRC_URI += "git://git@github.com/ocp-hm-openbmc-opf-ami/phosphor-post-code-manager.git;branch=master;protocol=https;name=override;"
SRCREV_FORMAT = "override"
SRCREV_override = "53b5e110c90e05d870fe406494b36eb42d46d254"

python () {
    if bb.utils.contains('EXTRA_IMAGE_FEATURES', 'onetree-multi-host-support', True, False, d) \
       and d.getVar('MULTI_HOST_DEFAULT_MODE') == '1':
        d.setVar('OBMC_HOST_INSTANCES', '1 2')
}
