FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI:append = " \
    file://0001-ARM-FVP-Firmware-Update-Support.patch \
    file://0002-Fix-for-BackupImage-not-showing-in-WebUI.patch \
    "

# FVP toolchain/libpldm combination may expose crc32() instead of
# pldm_edac_crc32(); map the newer symbol name to keep parser builds portable.
CXXFLAGS:append = " -Dpldm_edac_crc32=crc32"
