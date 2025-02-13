FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI:append = " file://aspeed-pfr-tool-ast2700.conf;subdir=${S}"
SYSTEMD_OVERRIDE:${PN} += "hotjoin.conf:BootCompleted.service.d/hotjoin.conf"

# This is for AST2700 A0 workaround.
# We need to wait for x86-power-control to initialize some of the SGPIOs output pins, 
# then send the BMC boot complete event to AST1060 to start the SGPIO passthrough function.
SYSTEMD_OVERRIDE:${PN} += "power.conf:BootCompleted.service.d/power.conf"

do_install:append() {
    install -m 0644 ${S}/aspeed-pfr-tool-ast2700.conf ${D}/${datadir}/pfrconfig/aspeed-pfr-tool.conf
}
