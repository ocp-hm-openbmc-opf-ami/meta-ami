SUMMARY = "Phosphor LED Group Management for Intel"
PR = "r1"

inherit obmc-phosphor-utils
inherit native

LICENSE = "Proprietary"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta-core/meta/files/common-licenses/Intel-BMC-Base;md5=f66be55877b5b739110e445efdcf5fbc"

PROVIDES += "virtual/phosphor-led-manager-config-native"

SRC_URI += "file://led.yaml"
S = "${WORKDIR}"

# Overwrite the example led layout yaml file prior
# to building the phosphor-led-manager package
do_install() {
    SRC=${S}
    DEST=${D}${datadir}/phosphor-led-manager
    install -D ${SRC}/led.yaml ${DEST}/led.yaml
}
