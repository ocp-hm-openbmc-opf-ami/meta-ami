FILESEXTRAPATHS:append := "${THISDIR}/${PN}:"

# Todo: Commented out the patch to avoid build failure
# SRC_URI += " \
#    file://0001-Force-nbdkit-to-send-PATCH-as-upload-method.patch \
#   "

do_install:append() {
    rm -rf ${D}/usr/lib/nbdkit/filters
    for files in ${D}/usr/lib/nbdkit/plugins/*
    do
        if  [ $files != ${D}/usr/lib/nbdkit/plugins/nbdkit-curl-plugin.so ] &&
            [ $files != ${D}/usr/lib/nbdkit/plugins/nbdkit-file-plugin.so ]
        then
            rm -f $files
        fi
    done
}
