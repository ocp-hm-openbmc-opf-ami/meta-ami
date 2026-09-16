FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI += " \
    file://0001-libvncserver-Keyboard-LED-sync.patch \
    file://0002-JPEG-encoding-support.patch \
    file://0003-systemd-socket-activation-Support.patch \
    file://0004-OT-5268-Session-Information-Display-Enhancement.patch \
    file://0005-OT-7216-Blocks-PointerPos-Enc-in-multi-client-mode.patch \
    file://0006-OT-23479-Add-per-client-desktop-name-support.patch \
    "
SRCREV = "42494999e6492aaab9c1db785ecd293ef10b3aed"

inherit pkgconfig
