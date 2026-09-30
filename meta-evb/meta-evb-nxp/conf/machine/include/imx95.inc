# Copyright 2025-2026 NXP


KSOC = "imx95"
KBOARD = "evk"
KPKG = "19x19"
# KMACHINE = "${KSOC}-${KBOARD}"
CONFIG_BASENAME = "${KSOC}_${KPKG}_${KBOARD}"

#BMC_LINUX_DTS = "${KSOC}-${KPKG}-${KBOARD}.dtb"
BMC_LINUX_DTS = "imx95-19x19-evk-ep-adv7535.dtb"

include conf/machine/include/nxp.inc
#include conf/machine/imx95-15x15-lpddr4x-frdm.conf
include conf/machine/imx95-19x19-lpddr5-evk.conf
