FILESEXTRAPATHS:append := ":${THISDIR}/${PN}"

SRC_URI += " \
    file://0001-libvncserver-Keyboard-LED-sync.patch \
    file://0002-JPEG-encoding-support.patch \
    "
SRCREV = "784cccbb724517ee4e36d9938f93b9ee168a29e7"
