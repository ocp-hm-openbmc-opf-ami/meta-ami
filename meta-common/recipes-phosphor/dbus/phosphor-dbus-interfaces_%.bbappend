FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI += "git://git.ami.com/core/ami-bmc/one-tree/core/phosphor-dbus-interfaces.git;branch=main;protocol=https;name=override;"

SRCREV_FORMAT = "override"
SRCREV_override = "38323614f9de788a618c98b9a86b764ac04afa11"

# Include NVIDIA D-Bus interface patches for non-NVIDIA GPGPU builds.
include ${@bb.utils.contains('BBFILE_COLLECTIONS', 'nvidia-layer', 'phosphor-dbus-interfaces_nv.inc', bb.utils.contains('EXTRA_IMAGE_FEATURES', 'onetree-gpgpu', 'phosphor-dbus-interfaces_nv.inc', '', d), d)}

EXTRA_OEMESON += "-Ddata_com_ami=true"
EXTRA_OEMESON += "-Ddata_org_open_power=true"

do_write_config[depends] = ""
addtask write_config after do_unpack do_patch before do_configure
