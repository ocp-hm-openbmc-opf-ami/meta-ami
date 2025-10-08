FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

#SRCREV = "41ebd7abf42ef8fdfe4867f865c56063517edb6f"
#SRCREV = "aa25b313ea3358104c5836b0d1e2c240aada59fb"
#SRC_URI += "file://0001-Add-secured-message-type-in-mctpd.patch"

SRC_URI:append:2700-dcscm-features = " \
    file://0001-2700-DCSCM-BHS-mctpd-changes.patch \
    "
