FILESEXTRAPATHS:append := ":${THISDIR}/${PN}"

SRC_URI += "    file://0001-ast2700_enable_all_uart.patch \
                file://0002-x86-power-control-gpio-config-2700.patch \
           "
