FILESEXTRAPATHS:append := "${THISDIR}/${PN}:"

SRC_URI += " \ 
        file://CVE-2024-33599.patch \
        file://CVE-2024-33601_CVE-2024-33602.patch \
        file://CVE-2024-2961.patch \
        file://CVE-2025-0395.patch \
        file://CVE-2025-8058.patch \
        "

