# Drop AST2600-only U-Boot patches for tiogapass.
SRC_URI:remove = "file://0005-Fix-NCSI-in-UBoot.patch"

SRC_URI:remove = "file://ast2600_a3.json"
SRC_URI:remove = "file://0001-board-ast2600-Remove-eSPI-PC-and-VW-initialization-c.patch"
SRC_URI:remove = "file://0001-dts-ast2600-evb-tee-Refine-sd-emmc-for-ultra-high-sp.patch"

# Drop AST2600 DisplayPort patches.
SRC_URI:remove = "file://0001-Add-aspeed-AST2600-DP-CTS-command-utility.patch"
SRC_URI:remove = "file://0001-ast2600-dp-fw-Fix-abnormal-link-training-cmd.patch"
SRC_URI:remove = "file://0001-Updated-U-Boot-Patches-for-DP-and-VGA-Support.patch"

# Drop AST2600 network driver patches.
SRC_URI:remove = "file://0009-net-ftgmac100-get-tx-rx-internal-delay-ps.patch"
SRC_URI:remove = "file://0010-ARM-dts-ast2600-add-aspeed-scu-property-for-MAC.patch"
SRC_URI:remove = "file://0011-net-ftgmac100-Add-RGMII-delay-support-for-AST2600.patch"
