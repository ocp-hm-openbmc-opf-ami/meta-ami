FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"
SRC_URI += "file://001-Adding-PCIe-Binding-support.patch \
	    file://002-Increased-timeout-verify-state.patch \ 
	    file://003-Increased-maximum-transfer-size.patch \
	    file://004-enabled-update-option-flag.patch \
	    file://005-Disabled-self-contained-activation.patch \
	    file://006-FRU-IANA-Segmentation-fault-fix.patch \
	    file://007-FRU-Checksum-verfication-removal.patch "

SRC_URI:append = " \
    file://008-dbus-utils-port.patch \
    file://009-mctp-endpoint-discovery.patch \
    file://010-add-mctp-demux-fd-and-pldm-send-recv-apis.patch \
    file://011-add-setup-event-loop.patch \
    file://012-remove-mctp-wrapper-dependency.patch \
    file://013-add-timer-to-event-loop.patch \
    file://014-added-msg-tag-support.patch \
    file://015-add_association_interface_to_pldm_sensors.patch \
    file://016-Fix-For-LF-Sync.patch \
    file://xyz.openbmc_project.pldmd.service \
"

DEPENDS += " nlohmann-json"
DEPENDS:remove = "mctpwplus mctp-wrapper"

do_install:append() {
    install -D -m 0644 ${UNPACKDIR}/xyz.openbmc_project.pldmd.service ${D}${systemd_system_unitdir}/xyz.openbmc_project.pldmd.service
}
SYSTEMD_SERVICE:${PN} = "xyz.openbmc_project.pldmd.service"
