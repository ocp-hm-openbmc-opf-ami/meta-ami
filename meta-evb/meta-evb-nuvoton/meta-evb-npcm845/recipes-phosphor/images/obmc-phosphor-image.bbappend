FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

#IMAGE_INSTALL:append = " \
#        libmctp \ 
#        "

clean_pubkey() {
    pubkeypath=$(find ${IMAGE_ROOTFS} -name publickey)
    if [ -n "$pubkeypath" ]; then
      rm -rf ${pubkeypath}
    fi
}

ROOTFS_POSTPROCESS_COMMAND += " clean_pubkey; "
