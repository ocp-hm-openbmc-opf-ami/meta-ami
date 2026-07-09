# All sizes & offsets below are in KB

#flash-size
FLASH_SIZE = "65536"

#SectionName: "bmc"
FLASH_BMC_OFFSET:flash-65536 = "0"
FLASH_BMC_SIZE:flash-65536   = "65536"

#SectionName: "u-boot"
FLASH_UBOOT_OFFSET:flash-65536 = "0"
FLASH_UBOOT_SIZE:flash-65536   = "3840"

#SectionName: "u-boot-env"
FLASH_UBOOT_ENV_OFFSET:flash-65536 = "3840"
FLASH_UBOOT_ENV_SIZE:flash-65536   = "256"

#SectionName: "kernel"
FLASH_KERNEL_OFFSET:flash-65536 = "4096"
FLASH_KERNEL_SIZE:flash-65536   = "9472"

#SectionName: "rofs"
FLASH_ROFS_OFFSET:flash-65536 = "13568"
FLASH_ROFS_SIZE:flash-65536   = "48896"

#SectionName: "rwfs"
FLASH_RWFS_OFFSET:flash-65536 = "62464"
FLASH_RWFS_SIZE:flash-65536   = "3008"

#SectionName: "reserved"
FLASH_RESERVED_OFFSET:flash-65536 = "65472"
FLASH_RESERVED_SIZE:flash-65536   = "64"
