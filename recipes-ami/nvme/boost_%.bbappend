FILES:${PN} += "usr/lib/libboost_thread.so*"

BOOST_LIBS:class-target:intel += "thread"

FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"
#SRC_URI += "file://0001-boost_thread-created.patch"

