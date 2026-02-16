# Extends the search path the OpenEmbedded build system uses when looking for files and patches as it processes recipes and append files
FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

# The list of source files — local or remote
SRC_URI_EXT:append= " \
	file://collection_ext.hpp;subdir=git/ext/include \
	file://storage_ext.hpp;subdir=git/ext/include \
"
SRC_URI:append = "${@bb.utils.contains_any('IMAGE_FEATURES', 'onetree-msccraid onetree-nvme onetree-nvmebasic onetree-brcmraid onetree-brcmraid8 onetree-rtp', SRC_URI_EXT, '', d)}"

SRC_URI_LOG:append= " \
        file://log_services_ext.hpp;subdir=git/ext/include \
"
SRC_URI:append = "${@bb.utils.contains_any('IMAGE_FEATURES', 'onetree-msccraid onetree-brcmraid onetree-brcmraid8', SRC_URI_LOG, '', d)}"

EXTRA_OEMESON += "${@bb.utils.contains('IMAGE_INSTALL', 'pciesw-service', ' -Dami-pciesw=enabled','', d)}"
EXTRA_OEMESON += "${@bb.utils.contains('BBFILE_COLLECTIONS', 'evb-ast2600', ' -Dast2600-evb=enabled','', d)}"
EXTRA_OEMESON += "${@bb.utils.contains('BBFILE_COLLECTIONS', 'evb-nuvoton-npcm845', ' -Darbel-nuvoton=enabled','', d)}"
EXTRA_OEMESON += "${@bb.utils.contains('IMAGE_FEATURES', 'onetree-intelsipack', ' -Dami-nm=enabled', '', d)}"
EXTRA_OEMESON += "${@bb.utils.contains('IMAGE_FEATURES', 'onetree-2fa', ' -Dami-2fa=enabled','', d)}"
EXTRA_OEMESON += "${@bb.utils.contains('BBFILE_COLLECTIONS', 'egs', ' -Dami-egs=enabled','', d)}"
EXTRA_OEMESON += "${@bb.utils.contains('BBFILE_COLLECTIONS', 'bhs', ' -Dami-bhs=enabled','', d)}"
EXTRA_OEMESON += "${@bb.utils.contains('BBFILE_COLLECTIONS', 'aspeed-sdk-layer', ' -Dast2700-evb=enabled','', d)}"
