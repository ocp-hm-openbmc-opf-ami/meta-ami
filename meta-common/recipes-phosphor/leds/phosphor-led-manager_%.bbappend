FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

DEPENDS:append = " virtual/phosphor-led-manager-config-native"

RDEPENDS:${PN}:remove = "clear-once"

do_compile:prepend(){
         install -m 0644 ${STAGING_DATADIR_NATIVE}/${PN}/led-group-config.json ${S}/led-group-config.json
}

do_install:append(){
    install -d ${D}${datadir}/phosphor-led-manager
    install -m 0644 ${STAGING_DATADIR_NATIVE}/${PN}/led-group-config.json ${D}${datadir}/phosphor-led-manager/led-group-config.json
}
