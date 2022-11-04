FILESEXTRAPATHS:append := "${THISDIR}/${PN}:"
SRC_URI = "git://git@git.ami.com/core/oe/advanced-features/firmware.bmc.openbmc.applications.crashdump.git;branch=egs;protocol=ssh"
SRCREV = "79e3f8271fa7cb66c7a04e20ffdd157cd135d694"

# Copying the depricated header from kernel as a temporary fix to resolve build breaks.
# It should be removed later after fixing the header dependency in this repository.
SRC_URI += "file://asm/rwonce.h"

