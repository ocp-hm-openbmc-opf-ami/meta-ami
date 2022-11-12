FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRCREV = "097497fb7b2466e85d2800991bef92017b044cda"

SRC_URI += "\
	   file://0007-Change-Privilege-to-system-interface.patch \
	   file://0008-fix-sdr-count-issue.patch \
           file://0009-Removed-SetSelTime-ipmi-Handler.patch \
           file://0010-Add-warm-reset-config.patch \
           file://0011-For-GetSensorType-ipmi-command-issue-is-getting-resp.patch \
	   file://0012-Add-SDR-Support-for-Processor-Type-Sensor.patch \
	   file://dcmi_whitelists_conf.patch \
           file://0014-Added-Get-BT-Interface-Capabilities-ipmi-command-in-.patch \	
           "

