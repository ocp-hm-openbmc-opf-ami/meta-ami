FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"


SRC_URI:bhs-features = "git://git@git.ami.com/core/oe/advanced-features/firmware.bmc.openbmc.applications.memory-error-collector.git;protocol=ssh;branch=main"
SRCREV:bhs-features = "9327deb7cb9699b4e886c19f65ba5ef7d86537a0"


SRC_URI = "git://git@git.ami.com/core/oe/advanced-features/firmware.bmc.openbmc.applications.memory-error-collector.git;protocol=ssh;branch=egs"
SRCREV = "372cc00dd23bdf5f769fa74293938f793dbab978"

SRC_URI += "file://0001-yocto-update-fix.patch"