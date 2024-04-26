
KCS_DEVICE:append = " \
    ipmi-kcs9 \
    ipmi-kcs10 \
    ipmi-kcs11 \
"

SYSTEMD_SERVICE:${PN}:append = " \
    ${PN}@ipmi-kcs9.service \
    ${PN}@ipmi-kcs10.service \
    ${PN}@ipmi-kcs11.service \
"

