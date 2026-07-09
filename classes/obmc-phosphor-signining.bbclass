
SIGNING_KEY ?= "${STAGING_DIR_NATIVE}${datadir}/OpenBMC.priv"
INSECURE_KEY = "${@'${SIGNING_KEY}' == '${STAGING_DIR_NATIVE}${datadir}/OpenBMC.priv'}"
SIGNING_KEY_DEPENDS = "${@oe.utils.conditional('INSECURE_KEY', 'True', 'phosphor-insecure-signing-key-native:do_populate_sysroot', '', d)}"



make_signatures() {
	signature_files=""
        cd "${present_directory}"
	for file in "$@"; do
                pwd
                echo "openssl dgst -sha256 -sign ${SIGNING_KEY} -out "${file}.sig" $file"
		openssl dgst -sha256 -sign ${SIGNING_KEY} -out "${file}.sig" $file
		signature_files="${signature_files} ${file}.sig"
	done

	if [ -n "$signature_files" ]; then
		sort_signature_files=`echo "$signature_files" | tr ' ' '\n' | sort | tr '\n' ' '`
		cat $sort_signature_files > image-full
		openssl dgst -sha256 -sign ${SIGNING_KEY} -out image-full.sig image-full
		signature_files="${signature_files} image-full.sig"
	fi
}

do_generate_full_image_tar() {
    cd "${B}/imgfull"
    present_directory="${B}/imgfull"
    # add symlinks for the contents
    ln -sf "${DEPLOY_DIR_IMAGE}/image-mtd" "image-bmc"
    ln -sf ${B}/MANIFEST .
    # make_signatures image-bmc MANIFEST publickey
    tar -h -czvf "${DEPLOY_DIR_IMAGE}/${IMAGE_BASENAME}-image-update-full-${MACHINE}-${DATETIME}.tar" image-bmc MANIFEST 
    # make a symlink
    ln -sf "${IMAGE_BASENAME}-image-update-full-${MACHINE}-${DATETIME}.tar" "${DEPLOY_DIR_IMAGE}/image-update-full-${MACHINE}"
    ln -sf "${IMAGE_BASENAME}-image-update-full-${MACHINE}-${DATETIME}.tar" "${DEPLOY_DIR_IMAGE}/OBMC-full-${@ do_get_version(d)}-oob.bin"
    ln -sf "image-update-full-${MACHINE}" "${DEPLOY_DIR_IMAGE}/image-update-full"
    ln -sf "image-update-full-${MACHINE}" "${DEPLOY_DIR_IMAGE}/OBMC-full-${@ do_get_version(d)}-inband.bin"

}

do_generate_full_image_tar[vardepsexclude] = "DATETIME"
do_generate_full_image_tar[dirs] = "${S}/imgfull"
do_generate_full_image_tar[depends] += " \
        openssl-native:do_populate_sysroot \
        ${SIGNING_KEY_DEPENDS} \
        ${PN}:do_copy_signing_pubkey \
        "

do_image_signed_fitimage_rootfs() {
    cd "${B}/img"
    # make_signatures image-kernel image-rofs image-rwfs image-u-boot MANIFEST publickey
    tar -h -czvf "${DEPLOY_DIR_IMAGE}/${IMAGE_BASENAME}-image-update-${MACHINE}-${DATETIME}.tar" MANIFEST image-u-boot image-runtime image-kernel image-rofs image-rwfs 
    ln -sf "${IMAGE_BASENAME}-image-update-${MACHINE}-${DATETIME}.tar" "${DEPLOY_DIR_IMAGE}/image-update-${MACHINE}"
    ln -sf "${IMAGE_BASENAME}-image-update-${MACHINE}-${DATETIME}.tar" "${DEPLOY_DIR_IMAGE}/OBMC-${@ do_get_version(d)}-oob.bin"
    ln -sf "image-update-${MACHINE}" "${DEPLOY_DIR_IMAGE}/image-update"
    ln -sf "image-update-${MACHINE}" "${DEPLOY_DIR_IMAGE}/OBMC-${@ do_get_version(d)}-inband.bin"
}

do_image_signed_fitimage_rootfs[vardepsexclude] = "DATETIME"
do_image_signed_fitimage_rootfs[dirs] = "${S}"
do_image_signed_fitimage_rootfs[depends] += " \
        openssl-native:do_populate_sysroot \
        ${SIGNING_KEY_DEPENDS} \
        ${PN}:do_copy_signing_pubkey \
        "


python() {

        bb.build.addtask(
                'do_generate_full_image_tar',
                'do_build',
                ' do_copy_signing_pubkey do_generate_auto ', d)
        
        bb.build.addtask(
                'do_image_signed_fitimage_rootfs',
                'do_build',
                ' do_image_fitimage_rootfs ', d)
}

CLEANFUNCS += "clean_deploy_signed_image_artifacts"
python clean_deploy_signed_image_artifacts() {
    import os, glob
    deploy_dir = d.getVar('DEPLOY_DIR_IMAGE')
    if not deploy_dir or not os.path.isdir(deploy_dir):
        return

    machine = d.getVar('MACHINE') or ''
    image_basename = d.getVar('IMAGE_BASENAME') or d.getVar('PN') or ''

    patterns = [
        # full image tar files
        '%s-image-update-full-%s-*.tar' % (image_basename, machine),
        # signed image-update tar files
        '%s-image-update-%s-*.tar' % (image_basename, machine),
        # OBMC full oob/inband symlinks
        'OBMC-full-*-oob.bin',
        'OBMC-full-*-inband.bin',
        'OBMC-*-oob.bin',
        'OBMC-*-inband.bin',
    ]

    for pat in patterns:
        for f in glob.glob(os.path.join(deploy_dir, pat)):
            try:
                os.remove(f)
                bb.note("Removed %s" % f)
            except OSError:
                pass

    # Remove specific symlinks
    for name in ['image-update-full-%s' % machine, 'image-update-full',
                  'image-update-%s' % machine, 'image-update']:
        fpath = os.path.join(deploy_dir, name)
        if os.path.lexists(fpath):
            os.remove(fpath)
            bb.note("Removed %s" % fpath)
}

clean_pubkey() {
    pubkeypath=$(find ${IMAGE_ROOTFS} -name publickey)
    if [ -n "$pubkeypath" ]; then
      rm -rf ${pubkeypath}
    fi
}

ROOTFS_POSTPROCESS_COMMAND += " clean_pubkey; "
