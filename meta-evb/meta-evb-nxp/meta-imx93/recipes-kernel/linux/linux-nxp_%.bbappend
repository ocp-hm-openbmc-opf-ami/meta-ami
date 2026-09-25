require conf/machine/include/imx93.inc

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI += "file://imx_openbmc_defconfig"
SRC_URI += "file://0001-openbmc-add-support-for-imx93-evk-frdm-imx91-evk.patch"
SRC_URI += "file://0002-P3T2030-temperature-sensor-support-for-IMX.93.patch"

S = "${WORKDIR}/git"

do_kernel_metadata:prepend() {
    cp ${UNPACKDIR}/imx_openbmc_defconfig ${S}/arch/arm64/configs/
}