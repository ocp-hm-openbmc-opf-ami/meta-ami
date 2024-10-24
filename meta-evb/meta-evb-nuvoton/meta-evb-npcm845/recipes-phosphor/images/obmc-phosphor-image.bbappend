FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

IMAGE_INSTALL:append = " \
        default-fru \
        entity-manager \
        dbus-sensors \
        "
