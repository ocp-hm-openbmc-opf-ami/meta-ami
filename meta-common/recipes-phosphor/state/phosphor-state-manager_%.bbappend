FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

#Todo: Commented out the patch to avoid build failure
#SRCREV = "2eb6029cd9696b1db92c59e85a6752ac4ba4a5a0"


SRC_URI += "file://0001-Timer-Support-for-manager-reset-operation.patch"

SRC_URI += "file://0001-Fix-for-allowedHostTransitions-error.patch"
SRC_URI += "file://0001-Added-try-catch.patch"

