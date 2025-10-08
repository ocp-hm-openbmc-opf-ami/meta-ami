EXTRA_OECMAKE += "${@bb.utils.contains('IMAGE_FSTYPES', 'intel-pfr', '-DINTEL_PFR_ENABLED=ON', '', d)}"
EXTRA_OECMAKE += "${@bb.utils.contains('IMAGE_FSTYPES', 'intel-secboot', '-DINTEL_PFR_ENABLED=ON', '', d)}"
EXTRA_OECMAKE += "${@bb.utils.contains('EXTRA_IMAGE_FEATURES', 'validation-unsecure', '-DBMC_VALIDATION_UNSECURE_FEATURE=ON', '', d)}"
EXTRA_OECMAKE += "-DUSING_ENTITY_MANAGER_DECORATORS=OFF"

# The URI is required for the autobump script but keep it commented
# to not override the upstream value
# SRC_URI = "git://github.com/openbmc/intel-ipmi-oem.git;branch=master;protocol=https"
SRCREV = "77a44298a726b20e595ee596ce0018e00493ef7e"

inherit pkgconfig
FILESEXTRAPATHS:append := ":${THISDIR}/${PN}"

INTEL_SRC_URI += " \
        file://0007-Adding-the-ACPI-agent-support-to-Mdrv2-OEM-commands.patch \
        file://0008-Increase-MaxFWImageSize-to-avoid-transfer-failure.patch \
        file://0008-Add-missing-include.patch \
        "

# Telemetry Features:
INTEL_SRC_URI += " \
        file://telemetry/0001-Skip-PMT-during-exposing-IPMI-sensors.patch \
        "

SRC_URI:append = "${@bb.utils.contains('BBFILE_COLLECTIONS', 'meta-ami', '',INTEL_SRC_URI, d)}"
# OOB BIOS Features:
SRC_URI += " \
        file://oob-bios/0001-fix-in-oob-bios.patch \
	"