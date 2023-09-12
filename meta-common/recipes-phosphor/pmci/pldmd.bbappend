FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"
SRC_URI += "file://001-Adding-PCIe-Binding-support.patch \
	    file://002-Increased-timeout-verify-state.patch \ 
	    file://003-Increased-maximum-transfer-size.patch \
	    file://004-enabled-update-option-flag.patch \
	    file://005-Disabled-self-contained-activation.patch"
