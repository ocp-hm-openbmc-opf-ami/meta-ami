FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI  += "git://git@github.com/ocp-hm-openbmc-opf-ami/phosphor-debug-collector.git;branch=master;protocol=https;name=override; "
SRCREV_FORMAT = "override"
SRCREV_override = "f793d1b618406db870834619fbe7911f5dd972e7"

SRC_URI += "file://plugins.d/arpcntlconf \
	    file://plugins.d/arptableinfo  \
	    file://plugins.d/biospostcode  \
	    file://plugins.d/channelaccess  \
	    file://plugins.d/channelconfig  \
	    file://plugins.d/freemem  \
	    file://plugins.d/interrupts  \
	    file://plugins.d/iproute  \
	    file://plugins.d/kernalRingBuff  \
	    file://plugins.d/kernlcmdline  \
	    file://plugins.d/mountinfo  \
	    file://plugins.d/netstat  \
	    file://plugins.d/networkconfig  \
	    file://plugins.d/networkrouteinfo  \
	    file://plugins.d/pslist  \
	    file://plugins.d/selinfo  \
	    file://plugins.d/sensorread  \
	    file://plugins.d/slabinfo  \
	    file://plugins.d/softIRQs  \
	    file://plugins.d/tmpfilelist  \
	    file://plugins.d/varfilelist  \
            file://service_files/obmc-dump-monitor.service \
            file://service_files/ramoops-monitor.service \
            file://service_files/xyz.openbmc_project.Dump.Manager.service \
	   "

do_install:prepend() {
    # Copy service files from subdirectory to WORKDIR root so base recipe picks them up
    cp ${UNPACKDIR}/service_files/*.service ${UNPACKDIR}/
}

do_install:append() {
    install -d ${D}${dreport_plugin_dir}
    install -m 0755 ${UNPACKDIR}/plugins.d/* ${D}${dreport_plugin_dir}/
}
