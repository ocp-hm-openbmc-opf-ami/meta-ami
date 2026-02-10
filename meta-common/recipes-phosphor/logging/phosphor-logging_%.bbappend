FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

EXTRA_OEMESON:append = " -Derror_cap=350 -Derror_info_cap=900 -Dstorage-select=emmc_sdcard"

#SRCREV = "e8026679f89642e3336b8c5e495f6ab694988e7a"

SRCREV = "0b758fb0be1205fdb1a8b0790f091b5a5e0c77b0"

SRC_URI += "\
    file://0001-Add-linear-and-circular-SEL-policy-support.patch \
    file://0002-Added-SEL-Enable-Disable-via-Set-BMC-Global-Enables-.patch \
    file://0004-Add-Error-and-info-limit.patch \
    file://0005-Fix-For-SEL-Clear-logging-from-phosphor-logging.patch \
    file://0006-Added-separate-object-for-different-logType.patch \
    file://0007-changed-logs-storage-path.patch \
    file://0008-Fixed-clang-format-and-entryId-issues.patch \
    file://0009-Add-log-file-rotatecount-and-filesize-in-logrotate.patch \
    file://0010-Added-roll-over-to-ipmi-events.patch \
    file://0011-handle-sel-full-event.patch \
    file://0012-update-clang-format.patch \
    file://0013-Add-tcp-modules-enable-disable-using-transmission-protocols.patch \
    file://0014-Added-ObjectManager-Interface-For-EventEntry.patch \
    file://0015-Select-storage-type-for-error-log-storage.patch \
"
