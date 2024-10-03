PFR_IMAGE_MODE = "${@bb.utils.contains('MACHINE_FEATURES', 'cerberus-pfr', 'cerberus-pfr-signing-image', 'intel-pfr-signing-image', d)}"
inherit ${PFR_IMAGE_MODE}


# Generate PFR image for provisioned Redfish firmware update.
do_generate_static:append() {
    bb.build.exec_func("do_generate_pfr_manifest", d)
}

do_generate_static_tar:append() {
    do_generate_pfr_static_tar
}

do_generate_static_tar[depends] += \
    " obmc-phosphor-image:do_generate_static"

# Generate PFR BMC image manifest.
# Use "purpose=Host" and  ExtendedVersion="pfrbmc" for provisioned Redfish firmware update.
python do_generate_pfr_manifest() {
    purpose = "xyz.openbmc_project.Software.Version.VersionPurpose.Host"
    version = do_get_version(d)
    target_machine = d.getVar('MACHINE', True)
    extended_version = "pfrbmc"
    manifest_file = os.path.join(d.getVar('PFR_IMAGES_DIR', True), "MANIFEST")
    with open(manifest_file, 'w') as fd:
        fd.write('purpose={}\n'.format(purpose))
        fd.write('version={}\n'.format(version.strip('"')))
        fd.write('ExtendedVersion={}\n'.format(extended_version))
        fd.write('KeyType={}\n'.format(get_pubkey_type(d)))
        fd.write('HashType=RSA-SHA256\n')
        fd.write('MachineName={}\n'.format(target_machine))
}

do_generate_pfr_static_tar() {
    bmc_signed_image="bmc_signed_cap.bin"
    manifest_file="MANIFEST"
    publickey_file="publickey"
    output_bin="bmc_signed_cap.static.mtd.tar"

    cd ${PFR_IMAGES_DIR}
    ln -sf ${S}/publickey ${publickey_file}

    make_signatures ${bmc_signed_image} ${manifest_file} ${publickey_file}
    tar -h -cvf ${output_bin} ${bmc_signed_image} ${manifest_file} ${publickey_file} ${signature_files}

    install -m 0644 ${output_bin} ${PFR_DEPLOY_IMAGES_DIR}/.
}
