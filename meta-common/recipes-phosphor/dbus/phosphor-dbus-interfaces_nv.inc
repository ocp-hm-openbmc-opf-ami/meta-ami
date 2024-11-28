SRC_URI:prepend = " \
        file://nv/0001-Added-nvidia-related-yaml-files-for-pldm-integration.patch \
        file://nv/0002-Add-SPDM-configurations.patch \
        file://nv/0003-Integrate-dbus-interfaces-changes-required-for-meta-.patch \
        file://nv/0004-phosphorus-debug-collector-package-integration.patch \
"
SRC_URI:append = " \
        file://nv/Asset.interface.yaml \
        file://nv/Version.interface.yaml \
        file://nv/Value.interface.yaml \
        file://nv/PowerSystemInputs.interface.yaml \
        file://nv/OperationalStatus.interface.yaml \
	file://nv/PortState.interface.yaml \
	file://nv/OT-2.0-PLDM-rebase-PortState_yaml_meson_buld_file.patch \
	file://nv/OT-2.0-PLDM-rebase-PortInfo_yaml.patch \
	file://nv/0005-Modifying_Auto_Gen_D-Bus_Files_for_nsmd.patch \
	file://nv/0006-Adding_Auto_Gen_D-Bus_Files_for_nsmd.patch \
"

do_replace_files() {
    # Replace or add files to the ${S} directory, which is the source code directory cloned from git
    install -m 0644 ${WORKDIR}/nv/Asset.interface.yaml ${S}/yaml/xyz/openbmc_project/Inventory/Decorator/
    install -m 0644 ${WORKDIR}/nv/Version.interface.yaml ${S}/yaml/xyz/openbmc_project/Software/
    install -m 0644 ${WORKDIR}/nv/Value.interface.yaml ${S}/yaml/xyz/openbmc_project/Sensor/
    install -m 0644 ${WORKDIR}/nv/PowerSystemInputs.interface.yaml ${S}/yaml/xyz/openbmc_project/State/Decorator/
    install -m 0644 ${WORKDIR}/nv/OperationalStatus.interface.yaml ${S}/yaml/xyz/openbmc_project/State/Decorator/
    install -m 0644 ${WORKDIR}/nv/PortState.interface.yaml ${S}/yaml/xyz/openbmc_project/Inventory/Decorator/
}
addtask replace_files after do_patch before do_configure

EXTRA_OEMESON += "-Ddata_com_nvidia=true"

