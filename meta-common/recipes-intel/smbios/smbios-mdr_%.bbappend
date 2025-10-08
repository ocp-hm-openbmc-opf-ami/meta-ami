FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

# Enable downstream autobump
# The URI is required for the autobump script but keep it commented
# to not override the upstream value
# SRC_URI = "git://github.com/openbmc/smbios-mdr.git;branch=master;protocol=https"

PACKAGECONFIG[assoc-trim-path] = ""
PACKAGECONFIG[cpuinfo-peci] = ""

SRCREV = "21cb0e8750b76fff5860b985d8122fd653ca8a1f"
SRC_URI += " \
    file://0001-Adding-patch-for-smbios-mdr-for-defaultTimeout.patch \
    file://0002-Catch-PECIErrors-from-supportsControl.patch \
    file://0003-sst-Don-t-always-wake-idle-CPU.patch \
    "

DEPENDS += " \
    nlohmann-json \
    "

# Maintain TPMI support downstream until it is publicly supported
#SRC_URI:append:bhs-features = " file://sst_tpmi.cpp;subdir=git/src"
#do_patch_tpmi() {
#}
#do_patch_tpmi:bhs-features() {
#    # Add the new file into the build next to the mailbox backend
#    sed -i 's|\(sst_mailbox.cpp\)|\1 src/sst_tpmi.cpp|' ${S}/CMakeLists.txt
#}
#do_patch[postfuncs] += "do_patch_tpmi"
