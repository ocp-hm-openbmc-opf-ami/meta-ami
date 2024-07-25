# Extends the search path the OpenEmbedded build system uses when looking for files and patches as it processes recipes and append files
FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

# The list of source files — local or remote
#SRC_URI:append 
SRC_URI_EXT:append= " \
	file://0001-Added-Routing-tables-for-MSCC-BRCM-NVME.patch \
	file://collection_ext.hpp;subdir=git/redfish-core/lib/ext \
	file://storage_ext.hpp;subdir=git/redfish-core/lib/ext \
"
SRC_URI:append = "${@bb.utils.contains_any('IMAGE_INSTALL', 'raid-mscc nvme-mgmt nvmebasic-mgmt raid-mgmt', SRC_URI_EXT, '', d)}"

EXTRA_OEMESON += "${@bb.utils.contains_any('IMAGE_INSTALL', 'nvme-mgmt nvmebasic-mgmt', ' -Dami-nvme=enabled','', d)}"
EXTRA_OEMESON += "${@bb.utils.contains('IMAGE_INSTALL', 'raid-mscc', ' -Dami-raidmscc=enabled','', d)}"
EXTRA_OEMESON += "${@bb.utils.contains('IMAGE_INSTALL', 'raid-mgmt', ' -Dami-raidbrcm=enabled','', d)}"
EXTRA_OEMESON += "${@bb.utils.contains('IMAGE_INSTALL', 'nic-mgmt', ' -Dami-nic=enabled','', d)}"
EXTRA_OEMESON += "${@bb.utils.contains('IMAGE_INSTALL', 'redfish-core', ' -Dami-rep=enabled','', d)}"
