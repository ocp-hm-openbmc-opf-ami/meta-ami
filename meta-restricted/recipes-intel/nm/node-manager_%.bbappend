FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRCREV ="02cb773779b6930f9769cd00513b64da586be07a"

SRC_URI += " \
    file://0001-Add-DCMI-command-handler-support.patch \
    file://0002-Setting-NM_INITIALIZATION_MODE-as-2.patch \
    file://0003-Support-to-Enable-SPS-NM-at-BMC-NM-Init-Mode-3.patch \
    file://0004-Fix-for-NM-Log-level.patch \
    file://0005-Removed-srf-support-for-build-error-fix.patch \
    file://0006-Removed-Multi-PsysSupport.patch \ 
    file://0007-Fix-for-Policy-Creation-with-Busctl.patch \
    "
