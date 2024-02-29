SRCREV = "0afdd8cc08adb5a5657766cc259fb7e98a0d807f"
FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI += " \
            file://ipmb-channels.json \
           "
do_install:append() {
    install -D ${WORKDIR}/ipmb-channels.json \
               ${D}/usr/share/ipmbbridge
}

