FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SYSTEMD_SERVICE:${PN}:remove = "nfs-server.service \
                                proc-fs-nfsd.mount "

do_install:append () {
	rm  ${D}${systemd_system_unitdir}/nfs-server.service
        rm  ${D}${systemd_system_unitdir}/proc-fs-nfsd.mount
}
