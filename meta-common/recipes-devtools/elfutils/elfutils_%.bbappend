FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"


SRC_URI:append = " \
                 file://0001-Fix-Compilation-Werror-on-GZIP.patch \
                 file://CVE-2025-1377.patch \
                 file://CVE-2025-1365.patch \
                 file://CVE-2025-1372.patch \
                 file://CVE-2025-1371.patch \
                 file://CVE-2025-1352.patch \
                 "


