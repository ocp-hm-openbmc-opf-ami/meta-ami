FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI += "git://git.ami.com/core/ami-bmc/one-tree/core/service-config-manager.git;branch=master;protocol=https;name=override;"
SRCREV_FORMAT = "override"
SRCREV_override = "1dc652559c3b9e6cd0066d4e689df1215d9ab786"

SRC_URI += "\
                file://srvcfg.json \
                "

PACKAGECONFIG = " \
    persist-settings-to-file \
"

DEPENDS += "nlohmann-json"

do_install:append() {
    install -d ${D}/etc/srvcfg-manager/
    install -m 0644 ${UNPACKDIR}/srvcfg.json ${D}/etc/srvcfg-manager/

    if [ -n "${KVM_TIMEOUT}" ] && [ "${KVM_TIMEOUT}" -gt "30" ] && [ "${KVM_TIMEOUT}" -ne "900" ] && [ "${KVM_TIMEOUT}" -le "86400" ]; then
        sed -i '/start-ipkvm/,/}/{s/"timeout": [0-9]*/"timeout": '${KVM_TIMEOUT}'/}' \
            ${D}/etc/srvcfg-manager/srvcfg.json
    fi
}
