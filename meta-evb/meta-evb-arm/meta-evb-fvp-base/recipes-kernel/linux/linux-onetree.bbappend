FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

COMPATIBLE_MACHINE = "fvp"

SRC_URI:append = " \
    file://defconfig \
    file://0001-arm64-dts-fvp-Enable-virtio-rng-support.patch \
"

python do_set_local_version() {
    b = d.getVar("B")
    with open("%s/.config" % b, "r+") as f:
        lines = f.readlines()
        f.seek(0)
        for line in lines:
            if line.find("CONFIG_LOCALVERSION") == -1:
                f.write(line)
        f.truncate()

    conf_local_ver = "CONFIG_LOCALVERSION=\"-OneTree\""

    with open("%s/.config" % b, "a") as f:
        f.write(conf_local_ver + "\n")
}
addtask set_local_version before do_configure after do_kernel_configme