FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

inherit obmc-phosphor-systemd

# This is for AST2700 A0 workaround.
# We need to wait for x86-power-control to initialize some of the SGPIOs output pins,
# then send the BMC boot complete event to AST1060 to start the SGPIO passthrough function.
SYSTEMD_OVERRIDE:${PN}:ast2700-a0 += "power.conf:xyz.openbmc_project.PFR.Manager.service.d/power.conf"

# Add nostamp to avoid build failure when the machine changes from ast2700-a0 to a1.
do_configure[nostamp] = "1"
do_compile[nostamp] = "1"
do_install[nostamp] = "1"
