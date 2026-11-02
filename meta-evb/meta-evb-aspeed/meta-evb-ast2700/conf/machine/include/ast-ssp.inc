MACHINE_FEATURES:append = " ast-ssp"
MACHINEOVERRIDES .= ":ast-ssp"

# AST2600
# Do not load the "aspeed-ssp" module on boot.
KERNEL_MODULE_PROBECONF:append:aspeed-g6 = " aspeed-ssp"
module_conf_aspeed-ssp = "blacklist aspeed-ssp"

# AST2700
UBOOT_FIT_CONF_USER_LOADABLES:append:aspeed-g7 = ' ,\"sspfw\"'
PREFERRED_PROVIDER_virtual/bootloader = "u-boot-onetree"
PREFERRED_PROVIDER_u-boot = "u-boot-onetree"
PREFERRED_PROVIDER_u-boot-fw-utils = "u-boot-fw-utils-onetree"

PREFERRED_VERSION_u-boot-onetree = "v2023.10+%"
PREFERRED_VERSION_u-boot-fw-utils-onetree = "v2023.10+%"
