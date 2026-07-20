FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI += "  \
	   file://0001-Disable-nm-sensors.patch \
	   file://0002-fix-for-legacy-nm-version.patch \
           file://0003-update-CMAKE_CXX_STANDARD-to-23.patch \
	   "
