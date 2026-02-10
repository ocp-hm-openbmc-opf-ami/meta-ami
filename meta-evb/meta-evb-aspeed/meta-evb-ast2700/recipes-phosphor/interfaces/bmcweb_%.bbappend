FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

EXTRA_OEMESON:append= " \
    -Dhttp-body-limit=264 \
    "

# Use the old updater.
EXTRA_OEMESON:append = " \
    -Dredfish-updateservice-use-dbus=disabled \
"

SRC_URI:append = " \
    file://0001-bmcweb-fixes-virtual-media-buffer-overflow.patch \    
    "
#0002-Support-websocket-control-frame-callback.patch
#0003-Modify-Content-Security-Policy-CSP-to-adapt-WebAssem.patch 
