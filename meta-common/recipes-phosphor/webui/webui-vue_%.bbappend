# Enable downstream autobump
# The URI is required for the autobump script but keep it commented
# to not override the upstream value
# SRC_URI = "git://github.com/openbmc/webui-vue.git;branch=master;protocol=https"
# SRCREV = "f763cd2e39ffce9b10191402243e8704794f08ff"

# AMI own repository for webui-vue with main branch
SRC_URI = "git://git.ami.com/core/ami-bmc/one-tree/core/webui-vue.git;branch=main;protocol=https"

# Use AUTOREV to get the latest revision from the repository
# SRCREV = "${AUTOREV}"
SRCREV = "7a73bb4087f6f26463ddc01956a91e12bba78c71"

SRC_URI += " \
    file://login-company-logo.svg \
    file://logo-header.svg \
    "
FILESEXTRAPATHS:append := "${THISDIR}/${PN}:"
do_compile:prepend() {
  cp -vf ${S}/.env.ami ${S}/.env.intel
  cp -vf ${S}/.env.ami ${S}/.env
  cp -vf ${WORKDIR}/login-company-logo.svg ${S}/src/assets/images
  cp -vf ${WORKDIR}/logo-header.svg ${S}/src/assets/images
}
