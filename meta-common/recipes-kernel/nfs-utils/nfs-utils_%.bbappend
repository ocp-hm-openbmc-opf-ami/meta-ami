FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SYSTEMD_SERVICE:${PN}:remove = "nfs-server.service"

do_install:append () {
	rm  ${D}${systemd_system_unitdir}/nfs-server.service
}
