IMAGE_INSTALL:append = " bmc-init"
IMAGE_INSTALL:remove = " packagegroup-fsl-optee-imx "
IMAGE_INSTALL:append = " hp-pci-gop"

OBMC_WEBUI = "webui-vue"
OBMC_IMAGE_EXTRA_INSTALL:append:nxp = " webui-vue phosphor-image-signing"
