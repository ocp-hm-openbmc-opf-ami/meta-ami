FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRCREV ="22c1c7848b46745e53b2ea13678cec112eba49cc"

SRC_URI += " \
    file://0001-Add-DCMI-command-handler-support.patch \
    file://0002-Setting-NM_INITIALIZATION_MODE-as-2.patch \
    file://0003-Support-to-Enable-SPS-NM-at-BMC-NM-Init-Mode-3.patch \
    file://0004-Fix-For-D-bus-Set-Property-Not-Working.patch \
    file://0005-Fix-for-NM-Log-level.patch \
    "
