FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"
SRC_URI += "git://git.ami.com/core/ami-bmc/one-tree/core/phosphor-post-code-manager.git;branch=master;protocol=https;name=override;"
SRCREV_FORMAT = "override"
SRCREV_override = "d58c8a9aa8f96b6a9a4999d7fa8bb9681290956e"

python () {
    if bb.utils.contains('EXTRA_IMAGE_FEATURES', 'onetree-multi-host-support', True, False, d) \
       and d.getVar('MULTI_HOST_DEFAULT_MODE') == '1':
        d.setVar('OBMC_HOST_INSTANCES', '1 2')
}
