require recipes-kernel/zephyr-kernel/zephyr-image.inc
require zephyr-aspeed-src.inc

SUMMARY = "BootMCU runtime firmware"
PACKAGE_ARCH = "${MACHINE_ARCH}"

PROVIDES += "virtual/ibexfw"
PV = "1.0+git"

# Tag for v00.03.01
SRCREV_zephyr = "75778c5d07abbd37063cfebb94c63def3cb2770e"
ZEPHYR_BRANCH = "aspeed-main-v3.7.0"

ZEPHYR_BOARD_IBEXFW ??= "ast2700_evb/ast2700/bootmcu"
ZEPHYR_BOARD = "${ZEPHYR_BOARD_IBEXFW}"

ZEPHYR_SRC_DIR ??= "${ZEPHYR_BASE}/samples/boards/ast2700_evb/demo"
