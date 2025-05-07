FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

EXTRA_OEMESON += "-Dredfish-dump-log=enabled"
EXTRA_OEMESON += "-Dredfish-new-powersubsystem-thermalsubsystem=enabled"
EXTRA_OEMESON += "-Dredfish-provisioning-feature=enabled"
EXTRA_OEMESON += "-Dredfish-dbus-log=enabled"

# add "redfish-hostiface" group
GROUPADD_PARAM:${PN}:append = ";redfish-hostiface"

SRC_URI = "git://git.ami.com/core/ami-bmc/one-tree/core/bmcweb;branch=master;protocol=https;name=override;"
SRCREV_FORMAT = "override"
SRCREV_override = "be5c8e5fe09ece87750f0e4652548a95ee0e85b0"

EXTRA_OEMESON += "${@bb.utils.contains('BBFILE_COLLECTIONS', 'meta-mgx','-Dredfish-intel-feature=enabled','', d)}"
EXTRA_OEMESON += "${@bb.utils.contains('BBFILE_COLLECTIONS', 'mtmitchell-layer', '-Dredfish-intel-feature=enabled', '', d)}"

DEPENDS += "phosphor-snmp"


