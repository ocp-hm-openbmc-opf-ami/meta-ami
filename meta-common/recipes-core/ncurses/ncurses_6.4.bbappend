SRC_URI = "git://github.com/ThomasDickey/ncurses-snapshots.git;protocol=https;branch=master"
SRC_URI += "file://0001-tic-hang.patch \
           file://0002-configure-reproducible.patch \
           file://0003-gen-pkgconfig.in-Do-not-include-LDFLAGS-in-generated.patch \
           file://exit_prototype.patch \
           "
# Use the latest revision from the repository with tag "v6_4_20230625"
SRCREV = "8884a7e908ffc6e8a0b6bcbca5832fe3fc579343"

PV = "6.4-patch20230625+"

LIC_FILES_CHKSUM = "file://COPYING;md5=e5d73f273990f364d27f1313c3976557"
