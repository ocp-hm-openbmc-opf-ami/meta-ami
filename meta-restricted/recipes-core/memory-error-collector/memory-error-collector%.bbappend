FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI:bhs-features = "git://git@git.ami.com/core/oe/advanced-features/firmware.bmc.openbmc.applications.memory-error-collector.git;protocol=ssh;branch=main"
SRC_URI = "git://git@git.ami.com/core/oe/advanced-features/firmware.bmc.openbmc.applications.memory-error-collector.git;protocol=ssh;branch=egs"

SRCREV:bhs-features = "621e5e462f37e6332c91a743e1736269d621f982"
SRCREV = "f837b15f2c7a3010b2b75c291027326c96e116d9"
