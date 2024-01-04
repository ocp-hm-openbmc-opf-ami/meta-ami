FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI += "\
       file://0007-Change-Privilege-to-system-interface.patch \
       file://0008-fix-sdr-count-issue.patch \
       file://0009-Removed-SetSelTime-ipmi-Handler.patch \
       file://0010-enable-warm-reset-dcmi-and-smtp-commands.patch \
       file://0011-For-GetSensorType-ipmi-command-issue-is-getting-resp.patch \
       file://0012-Add-SDR-Support-for-Processor-Type-Sensor.patch \
       file://0014-Add-Watchdog2-Discrete-Sensor.patch \
       file://0015-Add-OOB-BIOS-support-OEM.patch \
       file://0016-Add-SMTP-IPMI-OEM-Commands-Support.patch \
       file://0018-fixed-add-sel.patch \
       file://0019-fix-platform-event-ipmi-command.patch\
       file://0020-fixed-redfish-clear-sel.patch \
       file://0001-accessing-Chassis-Force-Identity-reserved-bits.patch \
       file://0022-Add-IPMI-Get-Set-SEL-Policy-OEM-command.patch \
       file://0023-Get-SDR-with-the-Invalid-Record-ID-shows-invalid-req.patch \
       file://0024-Fix-for-chassis-identify-ipmi-standard-commands-givi.patch \
       file://0025-SEL-entries-used-percentage-showing-unknown.patch \
       file://0026-Add-read-cert-file-command.patch \
       file://0027-Support-Inband-Firmware-Update.patch \
       file://0028-Generic-discrete-sensor.patch \
       file://0029-add-acpi-system-power-discrete-sensor-type.patch \
       file://0030-Add-IPMI-Support-for-Power-Supply-Discrete-Sensor.patch \
       file://0031-Remove-legacy-Discrete-sensors-dead-code.patch \
       file://0033-Added-sensor_min-sensor_max-values-to-sdr-record.patch \
       file://0034-Fix-for-GetSMTP-ConfigParam5.patch \
       file://0034-SDR-Info-Free-space-support.patch \
       file://0035-fix-for-get-sdr-count.patch \
       file://0036-Add-Support-for-Battery-Discrete-Sensor.patch \
       file://0038-Create-ipmi-OEM-command-for-enable-and-disable-KCS-state.patch \
       file://0039-Add-CancelTask-IPMI-OEM-Commands-Support.patch \
       file://0039-Setting-a-sensor-upper-critical-value-affecting-othe.patch \
       file://0041-Enabled-flag-for-disable-the-get-chassis-power-statu.patch \
    "

SRC_URI_CORE:append = "file://0032-Add-Support-for-OS-Critical-Discrete-Sensor.patch"
SRC_URI_RESTRICTED:append = "file://0032-Rest-Add-Support-for-OS-Critical-Discrete-Sensor.patch"
SRC_URI:append = "${@bb.utils.contains('BBFILE_COLLECTIONS', 'restricted', SRC_URI_RESTRICTED, SRC_URI_CORE, d)}"
SRC_URI:append =" \
       file://0036-Add-DBus-SEL-Logging-support-over-IPMI.patch \
       file://0037-Handle-extra-byte-issue-in-SMTP.patch \
       file://0038-Minimise-the-use-of-if-in-finding-eventtype-code.patch \
"

EXTRA_OECMAKE +="-DIF_NON_INTEL_DISABLE=OFF"
