FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI += "git://git.ami.com/core/ami-bmc/one-tree/core/phosphor-dbus-interfaces.git;branch=main;protocol=https;name=override;"

SRCREV_FORMAT = "override"
SRCREV_override = "03e0bc586efe95155d3ac7525e376da0f3e98afb"

# Include NVIDIA D-Bus interface patches for non-NVIDIA GPGPU builds.
include ${@bb.utils.contains('BBFILE_COLLECTIONS', 'nvidia-layer', 'phosphor-dbus-interfaces_nv.inc', bb.utils.contains('EXTRA_IMAGE_FEATURES', 'onetree-gpgpu', 'phosphor-dbus-interfaces_nv.inc', '', d), d)}

EXTRA_OEMESON += "-Ddata_com_ami=true"
EXTRA_OEMESON += "-Ddata_org_open_power=true"

do_write_config[depends] = ""
addtask write_config after do_unpack do_patch before do_configure
