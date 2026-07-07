FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI += " \
            file://CVE-2025-8194.patch \
            file://CVE-2025-6069.patch \
            file://CVE-2025-12084.patch \
            file://CVE-2025-13836.patch \
            file://CVE-2025-13837.patch \
            file://CVE-2026-0865.patch \
            file://CVE-2026-1299.patch \
            file://CVE-2026-6100.patch \
            file://CVE-2026-2297.patch \
            file://CVE-2026-3298.patch \
            file://CVE-2026-4786.patch \
            file://CVE-2026-3644.patch \
            file://CVE-2026-1502.patch \
            file://CVE-2026-3446.patch \
           "
