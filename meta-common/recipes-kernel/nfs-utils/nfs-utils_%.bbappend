FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SYSTEMD_SERVICE:${PN}:remove = "nfs-server.service \
                                proc-fs-nfsd.mount "

do_install:append () {
        rm -f ${D}${systemd_system_unitdir}/nfs-server.service
        rm -f ${D}${systemd_system_unitdir}/proc-fs-nfsd.mount
        # Remove the alias symlink that points to nfs-server.service
        rm -f ${D}${systemd_system_unitdir}/nfsserver.service
        # Also clean up any preset references to nfsserver
        if [ -d ${D}${systemd_unitdir}/system-preset ]; then
                sed -i '/nfsserver.service/d' ${D}${systemd_unitdir}/system-preset/*.preset 2>/dev/null || true
        fi
}
