FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRCREV = "823895ba708c63f6ae4dcbfc266210f26c02c698"
S = "${WORKDIR}/git"
PV = "1.9.8+git"

# PIE-flag pruning is already part of pseudo 1.9.8's configure, so drop the
# poky patch that no longer applies. older-glibc-symbols.patch is refreshed for
# 1.9.8 via FILESEXTRAPATHS above.
SRC_URI:remove = "file://0001-configure-Prune-PIE-flags.patch"
