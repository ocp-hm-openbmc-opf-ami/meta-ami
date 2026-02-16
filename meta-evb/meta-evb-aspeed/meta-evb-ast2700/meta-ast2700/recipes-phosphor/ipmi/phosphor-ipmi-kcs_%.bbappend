# KCS0/1/2/3: Host0 LPC-KCS
# KCS8/9/10/11: Host0 PCIe-KCS
# KCS12/13/14/15: Host1 PCIe-KCS

KCS_DEVICE = " \
    ipmi-kcs0 \
    ipmi-kcs1 \
    ipmi-kcs2 \
    ipmi_kcs3 \
"

SYSTEMD_SERVICE:${PN} = " \
    ${PN}@ipmi-kcs0.service \
    ${PN}@ipmi-kcs1.service \
    ${PN}@ipmi-kcs2.service \
    ${PN}@ipmi_kcs3.service \
"
