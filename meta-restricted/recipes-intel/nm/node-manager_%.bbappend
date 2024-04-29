FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI += " \
    file://0001-Add-DCMI-command-handler-support.patch \
    file://0002-Setting-NM_INITIALIZATION_MODE-as-2.patch \
    file://0003-Support-to-Enable-SPS-NM-at-BMC-NM-Init-Mode-3.patch \
    file://0004-Fix-for-NM-Log-level.patch \
    file://0005-Fix-for-Policy-Creation-with-Busctl.patch \
    file://0006-Restricting-policy-than-capabilitiesrange.patch \
    file://0008-Fix-for-DCMI-Set-Power-Limit.patch \
    "
