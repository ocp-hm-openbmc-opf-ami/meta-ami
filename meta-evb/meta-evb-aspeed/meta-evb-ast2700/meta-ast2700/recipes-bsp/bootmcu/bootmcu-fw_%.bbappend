FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

do_deploy:append() {
    # prebuilt
    if [ -d ${S}/board/aspeed/ibex_ast2700/prebuilt ]; then
        if [ -n "$(ls -A ${S}/board/aspeed/ibex_ast2700/prebuilt)" ]; then
            install -m 644 ${S}/board/aspeed/ibex_ast2700/prebuilt/*.bin ${DEPLOYDIR}
        fi
    fi
}
