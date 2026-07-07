FILESEXTRAPATHS:prepend := "${THISDIR}/linux-onetree:"

# remove obmc-phosphor-kernel-version class to avoid conflicts in setting localversion
KERNEL_CLASSES:remove = " obmc-phosphor-kernel-version"

DEPENDS += "lzop-native"
DEPENDS += "${@bb.utils.contains('MACHINE_FEATURES', 'ast-secure', 'aspeed-secure-config-native', '', d)}"

SRC_URI:append = " file://ipmi_ssif.cfg "
SRC_URI:append = " file://mtd_test.cfg "
SRC_URI:append = " file://crpyto_manager.cfg "
SRC_URI:append:spi-nor-ecc = " file://jffs2_writebuffer.cfg "
SRC_URI:append = " file://iptables.cfg "

SRC_URI:append = "  file://nfs_cifs.cfg "

SRC_URI:append = " file://iproute2.cfg "
SRC_URI:append = " file://iproute.cfg "
SRC_URI:append = " file://bond.cfg "
SRC_URI:append = " file://aspeed-g7/ "
SRC_URI:append = " file://0001-Fix-spi-driver-issue.patch "

SRC_URI_AST2700_DUAL_IMAGE = "\
                                file://0001-Added-the-sysfs-file-for-Dual-Image-support-2700.patch \
                                file://0001-spi-aspeed-smc-add-ast2700-fmc-forward-declaration.patch \
				file://0001-Fixed-the-dula-image-booting-issue.patch \
				file://0001-spi-aspeed-smc-Add-ABR-boot-mode-detection-via-SCU-f.patch \
                file://0068-Fix-for-dual-image-hardware-failsafe-in-ast2700evb.patch \
"

SRC_URI:append:ast2700-default = " ${@bb.utils.contains('IMAGE_FEATURES', 'onetree-dual-image', d.getVar('SRC_URI_AST2700_DUAL_IMAGE'), '', d)}"

do_kernel_configme:prepend() {
    install -d ${S}/arch/arm64/configs
    cp ${UNPACKDIR}/aspeed-g7/aspeed_g7_defconfig ${S}/arch/arm64/configs/
}

python do_set_local_version() {
    s = d.getVar("S")
    b = d.getVar("B")
    local_ver_override = d.getVar("KERNEL_LOCALVERSION")
    conf_local_ver = ""
    remove_auto_config = False

    # Determine localversion value
    try:
        res = bb.process.run("git -C %s describe --tags --exact-match" % s)[0].strip("\n")

        if "devtool" in res:
            # Use old logic for devtool branch - ignore override
            version_ext = bb.process.run("git -C %s rev-parse --verify --short HEAD" % s)[0].strip("\n")
            conf_local_ver = 'CONFIG_LOCALVERSION=\"-%s-%s\"\n' % (res, version_ext)
            bb.warn("devtool branch detected, using tag + hash: %s" % conf_local_ver)
        elif local_ver_override:
            # Use override and disable auto config
            conf_local_ver = 'CONFIG_LOCALVERSION=\"%s\"\n' % local_ver_override
            remove_auto_config = True
            bb.warn("Using KERNEL_LOCALVERSION override: %s" % conf_local_ver)
        else:
            # Use git tag
            conf_local_ver = 'CONFIG_LOCALVERSION=\"-%s\"\n' % res
    except bb.process.ExecutionError:
        if local_ver_override:
            # Use override and disable auto config
            conf_local_ver = 'CONFIG_LOCALVERSION=\"%s\"\n' % local_ver_override
            remove_auto_config = True
            bb.warn("Using KERNEL_LOCALVERSION override: %s" % conf_local_ver)
        else:
            # Fallback to dirty-hash
            version = bb.process.run("git -C %s rev-parse --verify --short HEAD" % s)[0].strip("\n")
            conf_local_ver = 'CONFIG_LOCALVERSION=\"-dirty-%s\"\n' % version

    # Update .config file
    with open("%s/.config" % b, "r+") as f:
        lines = f.readlines()
        f.seek(0)
        for line in lines:
            # Always remove CONFIG_LOCALVERSION
            if "CONFIG_LOCALVERSION=" in line or line.startswith("CONFIG_LOCALVERSION="):
                continue
            # Remove CONFIG_LOCALVERSION_AUTO only if override is set
            if remove_auto_config and ("CONFIG_LOCALVERSION_AUTO" in line):
                continue
            f.write(line)
        f.truncate()

    # Append new config
    with open("%s/.config" % b, "a") as f:
        f.write(conf_local_ver)
        if remove_auto_config:
            f.write("# CONFIG_LOCALVERSION_AUTO is not set\n")

    return
}

addtask set_local_version before do_configure after do_kernel_configme
