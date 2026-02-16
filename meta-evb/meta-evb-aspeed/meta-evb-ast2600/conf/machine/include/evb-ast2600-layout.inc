# All sizes & offsets below are in KB
#flash-size
FLASH_SIZE = "65536"

#SectionName: "u-boot"
FLASH_UBOOT_OFFSET:flash-65536 = "0" 
FLASH_UBOOT_SIZE:flash-65536 = "896"

#SectionName: "u-boot-env"
FLASH_UBOOT_ENV_OFFSET:flash-65536 = "896" 
FLASH_UBOOT_ENV_SIZE:flash-65536 = "128"

#SectionName: "kernel"
FLASH_KERNEL_OFFSET:flash-65536 = "1024" 
FLASH_KERNEL_SIZE:flash-65536 = "9216"

#SectionName: "rofs"
FLASH_ROFS_OFFSET:flash-65536 = "10240" 
FLASH_ROFS_SIZE:flash-65536 = "46080"

#SectionName: "rwfs"
FLASH_RWFS_OFFSET:flash-65536 = "56320" 
FLASH_RWFS_SIZE:flash-65536 = "9152"

#SectionName: "reserved"
FLASH_RESERVED_OFFSET:flash-65536 = "65472" 
FLASH_RESERVED_SIZE:flash-65536 = "64"