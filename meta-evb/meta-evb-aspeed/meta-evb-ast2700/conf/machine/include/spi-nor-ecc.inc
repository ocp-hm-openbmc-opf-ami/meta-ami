# Support SPI NOR ECC Flash.

MACHINE_FEATURES:append = " spi-nor-ecc "
MACHINEOVERRIDES .= ":spi-nor-ecc"

PREFERRED_PROVIDER_virtual/bootloader = "u-boot-onetree"
PREFERRED_PROVIDER_u-boot = "u-boot-onetree"
PREFERRED_PROVIDER_u-boot-fw-utils = "u-boot-fw-utils-onetree"

PREFERRED_VERSION_u-boot-onetree = "v2023.10+%"
PREFERRED_VERSION_u-boot-fw-utils-onetree = "v2023.10+%"
