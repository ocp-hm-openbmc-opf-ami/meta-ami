# The short summary of the binary package for packaging systems
SUMMARY = "Redfish extension interface for bmcweb"
# The section in which packages should be categorized
SECTION = "redfish"
# The list of source licenses for the recipe
LICENSE = "Proprietary"
LIC_FILES_CHKSUM = "file://${AMIBASE}/COPYING.AMI;md5=65a69a674f34a9f30737c9f0abd4fc5c"
# The version of the recipe
PV = "1.0.0"
# The revision of the recipe
PR = "r0"
# Lists a recipe’s build-time dependencies
DEPENDS = "boost"

# The list of source files — local or remote
SRC_URI = "file://include/redfish/ami/extension/service.hpp;md5=a9f83afdf3b1dd54f5b6a3e810f0170d"

do_install() {
  install -d ${D}${includedir}/redfish/ami/extension
  install -m 644 ${WORKDIR}/include/redfish/ami/extension/service.hpp ${D}${includedir}/redfish/ami/extension
}
