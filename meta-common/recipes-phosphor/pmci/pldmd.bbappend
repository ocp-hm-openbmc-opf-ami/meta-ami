FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"
SRC_URI += "file://001-Adding-PCIe-Binding-support.patch \
	    file://002-Increased-timeout-verify-state.patch \ 
	    file://003-Increased-maximum-transfer-size.patch \
	    file://004-enabled-update-option-flag.patch \
	    file://005-Disabled-self-contained-activation.patch \
	    file://006-FRU-IANA-Segmentation-fault-fix.patch \
	    file://007-FRU-Checksum-verfication-removal.patch "

python() {
    extra_features = d.getVar('EXTRA_IMAGE_FEATURES', True)
    if 'use-lfmctp' in extra_features:
        d.appendVar('SRC_URI', ' \
    file://008-dbus-utils-port.patch \
    file://009-mctp-endpoint-discovery.patch \
    file://010-add-mctp-demux-fd-and-pldm-send-recv-apis.patch \
    file://011-add-setup-event-loop.patch \
    file://012-remove-mctp-wrapper-dependency.patch \
    file://013-add-timer-to-event-loop.patch \
    file://014-added-msg-tag-support.patch \
')
}

DEPENDS += " nlohmann-json"
DEPENDS:remove = "${@bb.utils.contains('EXTRA_IMAGE_FEATURES', 'use-lfmctp', 'mctpwplus mctp-wrapper', '', d)}"
