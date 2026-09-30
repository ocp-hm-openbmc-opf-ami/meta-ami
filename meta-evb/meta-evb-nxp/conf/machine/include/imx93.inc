# Copyright 2025-2026 NXP

KSOC = "imx93"
KBOARD = "frdm"
KPKG = "11x11"
# KMACHINE = "${KSOC}-${KBOARD}"
CONFIG_BASENAME = "${KSOC}_${KPKG}_${KBOARD}"

BMC_LINUX_DTS = "${KSOC}-${KPKG}-${KBOARD}.dtb"
BMC_LINUX_DEFCONFIG = "imx_openbmc_defconfig"

include conf/machine/include/nxp.inc
include conf/machine/imx93frdm.conf
#include conf/machine/imx93evk.conf
