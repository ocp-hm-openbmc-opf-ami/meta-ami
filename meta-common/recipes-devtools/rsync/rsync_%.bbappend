FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI += " \
             file://CVE-2026-43618.patch \
             file://CVE-2026-43620.patch \
             file://CVE-2026-43617.patch \
             file://CVE-2026-45232.patch \
             file://CVE-2025-10158.patch \
           "
