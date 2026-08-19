FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI:append = " \
                 file://CVE-2025-40909.patch \
                 file://CVE-2026-8376.patch \
                 file://CVE-2026-48961.patch \
                 file://CVE-2026-48959.patch \
                 file://CVE-2026-48962.patch \
                 "
