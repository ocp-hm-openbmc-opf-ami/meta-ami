FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

#PACKAGECONFIG:append = " asd-cert"
#PACKAGECONFIG[asd-cert] = "-Dconfig-asd=enabled,-Dconfig-asd=disabled"
PACKAGECONFIG:append = " authority-cert"

SRC_URI = "git://git.ami.com/core/ami-bmc/one-tree/core/phosphor-certificate-manager.git;branch=master;protocol=https;name=override;"
SRCREV_FORMAT = "override"
SRCREV_override = "b6c23f13ba009df836f8268565870465adbbd80a"
