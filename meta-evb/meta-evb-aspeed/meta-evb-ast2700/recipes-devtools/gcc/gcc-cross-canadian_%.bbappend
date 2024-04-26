do_install:append() {
        rm -rf ${D}${libdir}/gcc/${TARGET_SYS}/${BINV}/plugin

}

FILES:${PN}:remove = "\
     ${gcclibdir}/${TARGET_SYS}/${BINV}/plugin/include \
     ${gcclibdir}/${TARGET_SYS}/${BINV}/plugin/gtype.* \
"
