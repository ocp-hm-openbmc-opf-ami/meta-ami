SUMMARY = "AST2600 DevKit management applications"

inherit packagegroup

PACKAGES = " \
    ${PN}-chassis \
    ${PN}-fans \
    ${PN}-flash \
    ${PN}-system \
"

PROVIDES = "${PACKAGES}"
PROVIDES += "virtual/obmc-chassis-mgmt"
PROVIDES += "virtual/obmc-fan-mgmt"
PROVIDES += "virtual/obmc-flash-mgmt"
PROVIDES += "virtual/obmc-system-mgmt"

RPROVIDES:${PN}-chassis += "virtual-obmc-chassis-mgmt"
RPROVIDES:${PN}-fans += "virtual-obmc-fan-mgmt"
RPROVIDES:${PN}-flash += "virtual-obmc-flash-mgmt"
RPROVIDES:${PN}-system += "virtual-obmc-system-mgmt"

RDEPENDS:${PN}-chassis = "x86-power-control"
RDEPENDS:${PN}-fans = "phosphor-pid-control"
RDEPENDS:${PN}-flash = "phosphor-ipmi-flash"
# phosphor-webui was retired upstream; webui-vue is its replacement.
RDEPENDS:${PN}-system = "bmcweb webui-vue"