FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRCREV = "35b72d95eb68b43c581f0cbb089dd63728e5241d"

PACKAGECONFIG[oem] = "-Doem=${LIBPLDM_OEM},,,"
EXTRA_OEMESON:append = " -Dtests=disabled"
