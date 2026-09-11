FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

#IMAGE_INSTALL:append = " \
#        libmctp \ 
#        "

# for s997
IMAGE_INSTALL:append:s997 = " numctl"
IMAGE_INSTALL:append:s997 = " ledctl"

clean_pubkey() {
    pubkeypath=$(find ${IMAGE_ROOTFS} -name publickey)
    if [ -n "$pubkeypath" ]; then
      rm -rf ${pubkeypath}
    fi
}

ROOTFS_POSTPROCESS_COMMAND += " clean_pubkey; "
