FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

EXTRA_OEMESON:append = " \
    -Dhttp-body-limit=264 \
    -Dredfish-updateservice-use-dbus=disabled \
    "

# To avoid build error, commented out the below patches
#SRC_URI:append = " \
#    file://0001-bmcweb-fixes-virtual-media-buffer-overflow.patch \    
#    "
#0002-Support-websocket-control-frame-callback.patch
#0003-Modify-Content-Security-Policy-CSP-to-adapt-WebAssem.patch 
