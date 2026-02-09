# Ref. meta-core/meta-common/recipes-core/systemd/systemd_%.bbappend
# add some configuration overrides for at-scale-debug defaults
# file://0002-Add-event-log-for-system-time-synchronization.patch

# 2024/07/06 ASD upgrade 1.5.4, below old patch files, 
# will integrate to a new patch, naming "001_ASD_integration.patch"
# file://001_ami-asd-dbus.patch 
# file://002_default-asdCertificate-change.patch


FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI += " \
    file://001_ASD-integration.patch \
    file://002_OT-12593_fixJtagTestFailed.patch \
    file://003_OT-12607-fixCoverityIssue.patch \
    file://004_OT-20873_ClangFormat \
"
