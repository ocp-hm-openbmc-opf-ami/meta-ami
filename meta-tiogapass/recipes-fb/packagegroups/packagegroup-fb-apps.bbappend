# packagegroup-fb-apps-system hard-RDEPENDS on phosphor-gpio-monitor-monitor,
# which duplicates ownership of PS_PWROK/POWER_BUTTON with x86-power-control
# and crashes it with EBUSY. Drop it only for tiogapass; other Facebook
# boards using this shared packagegroup are unaffected.
RDEPENDS:${PN}-system:remove:tiogapass = "phosphor-gpio-monitor-monitor"
