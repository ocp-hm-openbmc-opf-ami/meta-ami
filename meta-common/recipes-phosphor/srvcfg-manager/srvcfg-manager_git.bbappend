FILESEXTRAPATHS:append := "${THISDIR}/${PN}:"

SRC_URI:append = " file://0001-Added-Virtualmedia-service-to-service-Config-Manager.patch \
                   file://0002-Added-ipmb-service-to-service-Config-Manager.patch \
                   file://srvcfg.json                                                     \
                   file://0003-Added-changes-to-add-MaxSess-and-SessTimeOut-dbus-pr.patch \
                 "

SRCREV = "de87972682912d5f50dc31d313aa7505e7325070"

DEPENDS += "nlohmann-json"

do_install:append() {
    install -d ${D}/etc/srvcfg-manager/
    install -m 0644 ${WORKDIR}/srvcfg.json ${D}/etc/srvcfg-manager/
}
