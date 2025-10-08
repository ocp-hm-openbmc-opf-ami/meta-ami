FILESEXTRAPATHS:prepend := "${THISDIR}/files:"
SRC_URI += "file://0001-hw-arm-aspeed-Add-an-intel-ast2500-machine-type.patch \
            file://0002-hw-arm-aspeed-Add-an-intel-ast2600-machine-type.patch \
            file://0003-Remove-clearing-aspeed-GPIO-registers.patch \
            file://0004-Change-the-flash-part-of-QEMU-AST2600-evb-board.patch "

QEMU_TARGETS = "arm"
