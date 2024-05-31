FILESEXTRAPATHS:append := ":${THISDIR}/${PN}"


SRC_URI:append = " \
                 file://0001-changed-prov-mode-from-Whitelist-to-Allowlist.patch \
                 "

