# All sizes & offsets below are in KB
#flash-size
FLASH_SIZE = "131072"

#SectionName: "bmc"
FLASH_BMC_OFFSET:flash-131072 = "0"
FLASH_BMC_SIZE:flash-131072 = "131072"

#SectionName: "u-boot"
FLASH_UBOOT_OFFSET:flash-131072 = "0" 
FLASH_UBOOT_SIZE:flash-131072 = "3840"

#SectionName: "u-boot-env"
FLASH_UBOOT_ENV_OFFSET:flash-131072 = "3840" 
FLASH_UBOOT_ENV_SIZE:flash-131072 = "256"

#SectionName: "kernel"
FLASH_KERNEL_OFFSET:flash-131072 = "4096" 
FLASH_KERNEL_SIZE:flash-131072 = "17600"

#SectionName: "rofs"
FLASH_ROFS_OFFSET:flash-131072 = "21696" 
FLASH_ROFS_SIZE:flash-131072 = "68608"

#SectionName: "rwfs"
FLASH_RWFS_OFFSET:flash-131072 = "90304" 
FLASH_RWFS_SIZE:flash-131072 = "19392"

#SectionName: "reserved"
FLASH_RESERVED_OFFSET:flash-131072 = "109696" 
FLASH_RESERVED_SIZE:flash-131072 = "64"
