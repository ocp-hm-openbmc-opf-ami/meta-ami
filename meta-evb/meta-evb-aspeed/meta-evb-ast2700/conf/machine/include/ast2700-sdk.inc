SOC_FAMILY = "aspeed-g7"
include conf/machine/include/soc-family.inc
require conf/machine/include/aspeed-sdk.inc

DEFAULTTUNE = "cortexa35"

require conf/machine/include/arm/armv8a/tune-cortexa35.inc
require conf/machine/include/ast-arm-trusted-firmware-a.inc
require conf/machine/include/ast-bootmcu.inc

SERIAL_CONSOLES ?= "115200;ttyS12"

# bootloader fitimage
UBOOT_FIT_UBOOT_ENTRYPOINT ?= "0x80000000"
UBOOT_FIT_UBOOT_LOADADDRESS ?= "0x80000000"
UBOOT_FIT_ARM_TRUSTED_FIRMWARE_A_LOADADDRESS ?= "0xb0000000"
UBOOT_FIT_ARM_TRUSTED_FIRMWARE_A_ENTRYPOINT ?= "0xb0000000"
UBOOT_FIT_OPTEE_OS_LOADADDRESS ?= "0xb0080000"
UBOOT_FIT_OPTEE_OS_ENTRYPOINT ?= "0xb0080000"

# kernel fitimage
FIT_ADDRESS_CELLS ?= "2"
UBOOT_ENTRYPOINT ?= "0x4 0x00000000"
UBOOT_LOADADDRESS ?= "0x4 0x00000000"

COMPATIBLE_MACHINE:aspeed-g7 = "aspeed-g7"
TFA_PLATFORM = "ast2700"

# optee for BL32.
TFA_SPD = "opteed"

# TFA default build is BL31.
TFA_BUILD_TARGET = "bl31"

# It is a shortcut for "make PLATFORM=aspeed PLATFORM_FLAVOR=ast2700"
OPTEEMACHINE = "aspeed-ast2700"

UBOOT_FIT_ARM_TRUSTED_FIRMWARE_A_IMAGE ?= "${DEPLOY_DIR_IMAGE}/${TFA_BUILD_TARGET}.bin"
UBOOT_FIT_OPTEE_OS_IMAGE ?= "${DEPLOY_DIR_IMAGE}/optee/tee-raw.bin"

