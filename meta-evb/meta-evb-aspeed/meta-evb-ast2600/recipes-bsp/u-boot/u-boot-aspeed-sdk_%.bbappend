FILESEXTRAPATHS:append := "${THISDIR}/files:"

COMPATIBLE_MACHINE = "evb-ast2600"

SRC_URI:append:emmc-sw-ami = " \
	file://emmc-support.cfg  \
	"

SRC_URI:append:evb-ast2600 = " \
    file://fw_env_evb.config \
    "
do_install:prepend () {
	if [ -e ${WORKDIR}/fw_env.config ] ; then
		cp ${WORKDIR}/fw_env_evb.config ${WORKDIR}/fw_env.config
	fi
}


