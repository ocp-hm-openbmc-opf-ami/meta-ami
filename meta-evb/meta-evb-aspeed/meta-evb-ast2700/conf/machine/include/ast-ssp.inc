MACHINE_FEATURES:append = " ast-ssp"

# Do not load the "aspeed-ssp" module on boot.
KERNEL_MODULE_PROBECONF:append = " aspeed-ssp"
module_conf_aspeed-ssp = "blacklist aspeed-ssp"
