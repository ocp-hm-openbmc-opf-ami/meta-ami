FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"
SRC_URI += " \
           file://dcmi_sensors.json \
	   file://dcmi_cap.json \
	   file://channel_config.json \	
           "

