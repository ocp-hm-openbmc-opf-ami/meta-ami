# aspeed-zephyr-project bootmcu
SRC_URI_ASPEED_ZEPHYR_PROJECT = "gitsm://github.com/AspeedTech-BMC/aspeed-zephyr-project;protocol=https"
ASPEED_ZEPHYR_PROJECT_BRANCH ??= "aspeed-master"
ASPEED_ZEPHYR_PROJECT_NOBRANCH ??= "0"

# Tag for v03.08
SRCREV_app = "e5862a5b048cc7ce7557c3d4600cb98faab66f3b"

SRC_URI += "\
    ${SRC_URI_ASPEED_ZEPHYR_PROJECT};name=app;branch=${ASPEED_ZEPHYR_PROJECT_BRANCH};destsuffix=${S}/aspeed-zephyr-project;nobranch=${ASPEED_ZEPHYR_PROJECT_NOBRANCH} \
"

ZEPHYR_MODULES:append = "\
${S}/aspeed-zephyr-project\;\
"

ZEPHYR_SRC_DIR ??= "${S}/aspeed-zephyr-project/apps/mcu-runtime"