FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI:remove = "git://git.ami.com/core/ami-bmc/one-tree/core/libapisensor.git;protocol=https;branch=main"
SRC_URI:prepend = "git://git@github.com/ocp-hm-openbmc-opf-ami/libapisensor.git;protocol=https;branch=integrate-onetree-latest"
