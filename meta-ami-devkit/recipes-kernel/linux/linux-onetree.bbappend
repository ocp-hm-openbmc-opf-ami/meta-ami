FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI:append:ami-devkit = " file://0001-restore-devkit-dts.patch;apply=no"

do_configure:append:ami-devkit() {
	patch --batch --forward --fuzz=0 -p2 -d ${S}/arch/arm/boot/dts/aspeed \
		< ${UNPACKDIR}/0001-restore-devkit-dts.patch
}
