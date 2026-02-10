# Remove phosphor-ipmi-ipmb from RDEPENDS:${PN}-system.
# IPMB support is now controlled by an onetree packagegroup.

RDEPENDS:${PN}-system:remove = "phosphor-ipmi-ipmb"
