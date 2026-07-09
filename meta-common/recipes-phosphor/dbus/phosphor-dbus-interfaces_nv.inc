SRC_URI:prepend = " \
        file://nv/0004-phosphorus-debug-collector-package-integration.patch \
"
SRC_URI:append = " \
        file://nv/Asset.interface.yaml \
        file://nv/Version.interface.yaml \
        file://nv/Value.interface.yaml \
        file://nv/PowerSystemInputs.interface.yaml \
        file://nv/OperationalStatus.interface.yaml \
	file://nv/PortState.interface.yaml \
        file://nv/BootStatus.interface.yaml \
        file://nv/Update-all-meson-build-files.patch \
        file://nv/0009-Add-csm-interfaces-for-state-manager.patch \
        file://nv/0010-nvidia-sync-changes-from-gb300nvl-ws-2506-branch.patch \
        file://nv/0011-Add-EMMC-dbus-properties.patch \
        file://nv/0001-Added-nsmd-related-changes-into-dbus.patch \
"

do_replace_files() {
    # Replace or add files to the ${S} directory, which is the source code directory cloned from git
    install -m 0644 ${UNPACKDIR}/nv/Asset.interface.yaml ${S}/yaml/xyz/openbmc_project/Inventory/Decorator/
    install -m 0644 ${UNPACKDIR}/nv/Version.interface.yaml ${S}/yaml/xyz/openbmc_project/Software/
    install -m 0644 ${UNPACKDIR}/nv/Value.interface.yaml ${S}/yaml/xyz/openbmc_project/Sensor/
    install -m 0644 ${UNPACKDIR}/nv/PowerSystemInputs.interface.yaml ${S}/yaml/xyz/openbmc_project/State/Decorator/
    install -m 0644 ${UNPACKDIR}/nv/OperationalStatus.interface.yaml ${S}/yaml/xyz/openbmc_project/State/Decorator/
    install -m 0644 ${UNPACKDIR}/nv/PortState.interface.yaml ${S}/yaml/xyz/openbmc_project/Inventory/Decorator/
    install -d ${S}/yaml/com/nvidia/RoT/
    install -m 0644 ${UNPACKDIR}/nv/BootStatus.interface.yaml ${S}/yaml/com/nvidia/RoT/
}
addtask replace_files after do_patch before do_configure

EXTRA_OEMESON += "-Ddata_com_nvidia=true"

