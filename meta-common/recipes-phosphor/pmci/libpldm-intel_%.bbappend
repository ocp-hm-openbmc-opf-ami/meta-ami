FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"
SRC_URI += "file://001-Decreased-Baseline-transfer-size.patch "
python() {
    extra_features = d.getVar('EXTRA_IMAGE_FEATURES', True)
    if 'use-lfmctp' in extra_features:
        d.appendVar('SRC_URI', ' \
    file://002-add-pldm-request-response-api.patch \
    file://003-add-tag-owner-msg-tag.patch \
')
}
