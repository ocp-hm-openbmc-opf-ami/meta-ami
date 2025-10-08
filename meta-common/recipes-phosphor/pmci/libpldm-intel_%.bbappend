FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"
SRC_URI += "file://001-Decreased-Baseline-transfer-size.patch "
SRC_URI:append = " \
    file://002-add-pldm-request-response-api.patch \
    file://003-add-tag-owner-msg-tag.patch \
"
