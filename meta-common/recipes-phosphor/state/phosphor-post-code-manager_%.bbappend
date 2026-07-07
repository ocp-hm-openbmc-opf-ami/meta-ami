FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"
SRC_URI += "git://git.ami.com/core/ami-bmc/one-tree/core/phosphor-post-code-manager.git;branch=master;protocol=https;name=override;"
SRCREV_FORMAT = "override"
SRCREV_override = "6b76468ad06c18686646c940999ccf20fe2e951c"

python () {
    if bb.utils.contains('EXTRA_IMAGE_FEATURES', 'onetree-multi-host-support', True, False, d) \
       and d.getVar('MULTI_HOST_DEFAULT_MODE') == '1':
        d.setVar('OBMC_HOST_INSTANCES', '1 2')
}

