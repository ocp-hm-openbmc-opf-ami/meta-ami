FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

do_install:append(){
        rm ${D}${bindir}/zipsplit ${D}${bindir}/zipnote ${D}${bindir}/zipcloak
}
