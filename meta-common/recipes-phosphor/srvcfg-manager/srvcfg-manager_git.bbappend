FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI:append = " file://0001-Added-Virtualmedia-PmtService-ipmb-to-Service-Config.patch \
		   file://0002-Added-changes-to-add-MaxSess-and-SessTimeOut-dbus-pr.patch \
		   file://0003-Create-D-Bus-object-path-after-managed-jobs-complete.patch \
		   file://0004-To-resolve-conflict-between-the-Managed-service-and-.patch \
		   file://0005-Synchronize-states-at-boot-and-fix-persistence.patch \
                   file://srvcfg.json                                                     \
                 "

SRCREV = "369074698ee4c4726feb6ca171e7aa8e92f3f449"

DEPENDS += "nlohmann-json"

do_install:append() {
    install -d ${D}/etc/srvcfg-manager/
    install -m 0644 ${UNPACKDIR}/srvcfg.json ${D}/etc/srvcfg-manager/

    if [ -n "${KVM_TIMEOUT}" ] && [ "${KVM_TIMEOUT}" -gt "30" ] && [ "${KVM_TIMEOUT}" -ne "900" ] && [ "${KVM_TIMEOUT}" -le "86400" ]; then
        sed -i '/start-ipkvm/,/}/{s/"timeout": [0-9]*/"timeout": '${KVM_TIMEOUT}'/}' \
            ${D}/etc/srvcfg-manager/srvcfg.json
    fi
}
