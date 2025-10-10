FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI:append = " \
                 file://CVE-2024-56406.patch \
                 file://CVE-2025-40909.patch \
                 "
