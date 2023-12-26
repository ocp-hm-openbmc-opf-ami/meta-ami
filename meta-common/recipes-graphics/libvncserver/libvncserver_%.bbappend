FILESEXTRAPATHS:append := ":${THISDIR}/${PN}"

SRC_URI += " \
    file://0001-libvncserver-Keyboard-LED-sync.patch \
    file://0002-JPEG-encoding-support.patch \
    "
