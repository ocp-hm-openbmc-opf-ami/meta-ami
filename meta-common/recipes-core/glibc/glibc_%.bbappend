FILESEXTRAPATHS:append := "${THISDIR}/${PN}:"

SRC_URI += " \
       file://CVE-2025-8058.patch \
       file://CVE-2026-0915.patch \
       file://CVE-2026-0861.patch \
       file://CVE-2025-15281.patch \
       file://CVE-2026-4438.patch \
        "

