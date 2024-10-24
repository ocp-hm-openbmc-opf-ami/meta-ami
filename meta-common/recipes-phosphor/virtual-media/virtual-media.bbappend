FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI += "file://0001-virtual-media-https-support.patch \
            file://0002-virtual-media-add-nfs-support.patch \
            file://0003-Disable-kernel-page-caching-in-mount.cifs.patch \
            file://0004-Added-eject-support.patch \
            file://0005-reduce-time-for-throwing-error-during-nfs-mount.patch \
            file://0006-VMM-Session-Management-Support.patch \
            file://0007-OT-3805-AST2700-Support.patch \
            file://0008-OT-3061-Posix-fadvise-cache-drop-for-virtual-media-r.patch \
            file://0009-OT-5816-Updated-SessionRegister-method-call.patch \
            file://0010-OT-4090-Addition-of-symlink-check.patch \
            file://0011-OT-7707-Fix-Command-Injection-in-Virtual-Media.patch \
            file://0012-OT-8043-Fix-privilege-escalation-in-virtual-media.patch \
            file://0011-Support-Nuvoton-NPCM845-UDC.patch \
           "

RDEPENDS:${PN} = "nbd-client nbdkit nfs-export-root"

