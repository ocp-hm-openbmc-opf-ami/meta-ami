# RDE repository revision (enabled if IMAGE_FEATURES contains onetree-rtp)
SRCREV_override = "8f02ad480851ea2fe9ee5c72b7125f78efed9d49"
SRC_URI += " ${@bb.utils.contains('EXTRA_OEMESON','-Dpldm-type6=enabled','git://git.ami.com/core/ami-bmc/one-tree/ami/ot-pldm-rde.git;protocol=https;branch=main;destsuffix=git/ot-pldm-rde;name=override','',d)}"

# Compose SRCPV from involved repos (main only or main + rde)
SRCREV_FORMAT = "${@bb.utils.contains('EXTRA_OEMESON','-Dpldm-type6=enabled','main_rde','main',d)}"
