FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI:append = " file://init-options"
SRC_URI:append = " file://init-options-common-conf"

do_install:append() {
    install -m 0644 ${UNPACKDIR}/init-options ${D}/init-options

    if ${@bb.utils.contains('IMAGE_FEATURES', 'onetree-dual-image-common-conf', 'true', 'false', d)}; then
        install -m 0755 ${UNPACKDIR}/init-options-common-conf ${D}/init-options
    fi
}
