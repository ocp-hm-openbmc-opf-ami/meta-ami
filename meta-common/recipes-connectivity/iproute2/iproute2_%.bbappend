FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

do_install:append() {
	install -d ${D}/etc/iproute2
	mv ${D}${libdir}/iproute2/rt_tables ${D}/etc/iproute2/rt_tables
	ln -sf ${@oe.path.relative('${D}${libdir}/iproute2', '${D}/etc/iproute2/rt_tables')} ${D}${libdir}/iproute2/rt_tables
}



