FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

#SYSTEMD_SUBSTITUTIONS_remove = "KCS_DEVICE:${KCS_DEVICE}:${DBUS_SERVICE_${PN}}"

# Default kcs device is ipmi-kcs3; this is SMS.
# Add SMM kcs device instance

# Replace the '-' to '_', since Dbus object/interface names do not allow '-'.
KCS_DEVICE = "ipmi_kcs3"
SMM_DEVICE = "ipmi_kcs4"
SYSTEMD_SERVICE:${PN}:append = " ${PN}@${SMM_DEVICE}.service "

# The URI is required for the autobump script but keep it commented
# to not override the upstream value
# SRC_URI = "git://github.com/openbmc/kcsbridge.git;branch=master;protocol=https"
SRCREV = "43c83c56507cd35982537e5a646ee716f8335b6c"

SRC_URI += "file://99-ipmi-kcs.rules"

do_install:append() {
    install -d ${D}${base_libdir}/udev/rules.d
    install -m 0644 ${WORKDIR}/99-ipmi-kcs.rules ${D}${base_libdir}/udev/rules.d/
}
