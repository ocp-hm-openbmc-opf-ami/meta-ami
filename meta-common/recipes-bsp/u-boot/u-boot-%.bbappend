FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI += " \
    file://fw_env.config \
    "

# This patch was removed from upstream for a new version of u-boot. We still
# it for our version of u-boot, so pull patch into downstream.
# Todo: Commented out the patch to avoid build failure
#SRC_URI += "file://0001-scripts-dtc-pylibfdt-libfdt.i_shipped-Use-SWIG_Appen.patch"

# Temporary workaround: With the old upstream u-boot this patch is already
# applied and fails the build. This removes the duplicate patch entry for the
# old uboot and can be removed after syncing to the new u-boot that doesn't
# apply this patch.
python () {
    src_uri_list = d.getVar('SRC_URI').split()
    src_uri_list = list(dict.fromkeys(src_uri_list))  # Remove duplicates while preserving order
    d.setVar('SRC_URI', ' '.join(src_uri_list))
}
