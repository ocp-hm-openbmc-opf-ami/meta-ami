COMPATIBLE_MACHINE = "evb-ast2600"

FILESEXTRAPATHS:append := ":${THISDIR}/${PN}"

SRC_URI:append:evb-ast2600 = " file://0001-openbmc-flash-layout-ami-evb-64-dtsi.patch \
                               file://enable_sgpio.cfg \ 
                               file://0002-Enable-SGPIO-Master-0-on-EVB.patch \
		               file://0001-Enabled-UART-ROUTING-to-EVB.patch \
		               file://0001-Enabled-UART-driver-to-EVB.patch \
                       file://0003-GPIO-Pin-Configurations-for-Power-Operations.patch \
                             "
                  
#SRC_URI:append:evb-ast2600 = " file://ast2600evb.config \
#                               file://0001-updated-aspeed-ast2600-evb.patch \
#			       file://0001-added-gpios-in-dts-for-x-86-power-control.patch \
#			       file://0002-added-pinctrl-lpc-reset.patch \
#			       file://0003-Enabling-UART-in-dts_ast2600evb.patch \
#                               file://0004-I2C-bus-error-message-for-fault-alarm-support.patch \
#                               file://0005-Added-gpios-in-dts-for-sensor-interrupt.patch \
#                               file://0006-Added-w25q01jvfim-Winbond-SPI.patch \
#                             "

