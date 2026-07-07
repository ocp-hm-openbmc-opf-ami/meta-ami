SUMMARY = "Default Fru"
DESCRIPTION = "Installs a default fru file to image"

SRC_URI = "file://baseboard.fru.bin"

LICENSE = "CLOSED"


do_install() {

    install -d ${D}${sysconfdir}/fru
    cp ${UNPACKDIR}/baseboard.fru.bin ${D}/${sysconfdir}/fru

}
