FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI += " \
    file://0001-libvncserver-Keyboard-LED-sync.patch \
    file://0002-JPEG-encoding-support.patch \
    file://0003-systemd-socket-activation-Support.patch \
    file://0004-OT-5268-Session-Information-Display-Enhancement.patch \
    file://0005-OT-7216-Blocks-PointerPos-Enc-in-multi-client-mode.patch \
    file://0006-OT-23479-Add-per-client-desktop-name-support.patch \
    "
SRCREV = "784cccbb724517ee4e36d9938f93b9ee168a29e7"

inherit pkgconfig
