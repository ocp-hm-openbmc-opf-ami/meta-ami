FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRCREV = "07339377c0dc97f9dc419878131b4161d3f42847"
SRC_URI += "file://0001-Add-Enable-After-Reset-support-in-biosconfig.patch \
            file://0002-Replaced-io-service-with-io-context.patch \
            "
