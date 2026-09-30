FILESEXTRAPATHS:prepend := "${THISDIR}/libbej:"

SRCREV = "be27f2e9bfab32d9281496614e3d15a49a4c6aa9"
SRC_URI += "file://0001-Fix-Bejdecoder-and-Add-bejResourceLink-Support.patch \
            file://0002-Add-Deferred-Binding-Support.patch \
            file://0003-Add-boundary-checks-for-offset-update.patch\
           "