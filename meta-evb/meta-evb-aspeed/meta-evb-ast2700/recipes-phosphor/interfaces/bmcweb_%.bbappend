FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

EXTRA_OEMESON:append = " \
    -Dhttp-body-limit=264 \
    -Dredfish-updateservice-use-dbus=disabled \
    "
