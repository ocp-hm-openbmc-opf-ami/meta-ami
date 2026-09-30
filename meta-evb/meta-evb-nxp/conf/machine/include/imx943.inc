# Copyright 2025-2026 NXP

KSOC = "imx943"
KBOARD = "evk"
# KMACHINE = "${KSOC}-${KBOARD}"
CONFIG_BASENAME = "${KSOC}_${KBOARD}"

BMC_LINUX_DTS = "${KSOC}-evk.dtb"

include conf/machine/include/nxp.inc
include conf/machine/imx943evk.conf
