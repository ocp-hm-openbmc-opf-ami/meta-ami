# RDE repository revision (enabled if IMAGE_FEATURES contains onetree-rtp)
SRCREV_override = "be6a3e01f8462b0677204b0649ed406d44036109"
SRC_URI += " ${@bb.utils.contains('EXTRA_OEMESON','-Dpldm-type6=enabled','git://git.ami.com/core/ami-bmc/one-tree/ami/ot-pldm-rde.git;protocol=https;branch=main;destsuffix=git/ot-pldm-rde;name=override','',d)}"

# Compose SRCPV from involved repos (main only or main + rde)
SRCREV_FORMAT = "${@bb.utils.contains('EXTRA_OEMESON','-Dpldm-type6=enabled','main_rde','main',d)}"
