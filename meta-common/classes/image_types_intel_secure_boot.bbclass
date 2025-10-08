inherit obmc-phosphor-full-fitimage
inherit image_types_phosphor_auto_secure_boot
DEPENDS += "secureboot \
            obmc-intel-pfr-image-native \
            intel-pfr-signing-utility-native \
            external-signing-utility-native \
            otp-capsule-generator-native \
            "

require recipes-core/os-release/version-vars.inc

IMAGE_TYPES += "intel-secboot"

IMAGE_TYPEDEP:intel-secboot = "mtd-auto"
IMAGE_TYPES_MASKED += "intel-secboot"

# Secure boot images directory
SECBOOT_IMAGES_DIR = "${DEPLOY_DIR_IMAGE}/secboot_images"

# Secure Boot image generation script directory
SECBOOT_SCRIPT_DIR = "${STAGING_DIR_NATIVE}${bindir}"

# Secure boot image config directory
SECBOOT_CFG_DIR = "${STAGING_DIR_NATIVE}${datadir}/pfrconfig"

# Refer flash map in manifest.json for the addresses offset
PFM_OFFSET = "0x80000"

# 0x80000/1024 = 0x200 or 512, 1K Page size.
PFM_OFFSET_PAGE = "512"

# 0x4080000/1024 = 0x10200 or 66048, 1K Page size.
PFM_OFFSET_PAGE_B = "66048"

# PFM SVN VERSION NUMBER
PFM_SVN = "1"

# OTP Image directory
OTP_IMAGE_DIR = "${DEPLOY_DIR_IMAGE}/otp_image"

generate_otp_capsule() {
    local pfm_manifest_json="pfm_manifest${bld_suffix}.json"
    local pfmconfig_xml="pfm_config${bld_suffix}.xml"
    local otpconfig_xml="otp_config${bld_suffix}.xml"
    local SIGN_UTILITY=${SECBOOT_SCRIPT_DIR}/intel-pfr-signing-utility

    otp-capsule-generator -m ${SECBOOT_CFG_DIR}/${pfm_manifest_json} -i ${OTP_IMAGE_DIR}/otp-all.image -n ${build_version} -b ${build_number} \
            -h ${build_hash} -s ${SHA}

    ${SIGN_UTILITY} -c ${SECBOOT_CFG_DIR}/${pfmconfig_xml} -o ${OTP_IMAGE_DIR}/pfm_signed.bin ${SECBOOT_IMAGES_DIR}/pfm_header.bin -v

    dd if=${OTP_IMAGE_DIR}/pfm_signed.bin bs=1k >> ${OTP_IMAGE_DIR}/otp_unsigned_cap.bin

    dd if=${OTP_IMAGE_DIR}/otp-all.image bs=1k >> ${OTP_IMAGE_DIR}/otp_unsigned_cap.bin

    ${SIGN_UTILITY} -c ${SECBOOT_CFG_DIR}/${otpconfig_xml} -o ${OTP_IMAGE_DIR}/otp_signed_cap.bin ${OTP_IMAGE_DIR}/otp_unsigned_cap.bin -v
}

do_image_secboot_internal () {
    local manifest_json="pfr_manifest${bld_suffix}.json"
    local pfmconfig_xml="pfm_config${bld_suffix}.xml"
    local bmcconfig_xml="bmc_config${bld_suffix}.xml"
    local pfm_signed_bin="pfm_signed${bld_suffix}.bin"
    local signed_cap_bin="bmc_signedcap${bld_suffix}.bin"
    local unsigned_cap_bin="bmc_unsigned_cap${bld_suffix}.bin"
    local unsigned_cap_align_bin="bmc_unsigned_cap${bld_suffix}.bin_aligned"
    local output_bin="image-mtd-pfr${bld_suffix}"
    local SIGN_UTILITY=${SECBOOT_SCRIPT_DIR}/intel-pfr-signing-utility
    local bmcconfig_spl_xml="bmc_config${bld_suffix}_spl.xml"
    local signed_cap_spl_bin="bmc_signedcap${bld_suffix}-${DATETIME}_spl.bin"
    local unsigned_cap_spl_bin="bmc_unsigned_cap${bld_suffix}-${DATETIME}_spl.bin"

    # python script that does creating PFM & BMC unsigned, compressed image (from BMC 128MB raw binary file).
    ${SECBOOT_SCRIPT_DIR}/pfr_image.py -m ${SECBOOT_CFG_DIR}/${manifest_json} -i ${DEPLOY_DIR_IMAGE}/image-mtd -n ${build_version} -b ${build_number} \
        -h ${build_hash} -s ${SHA} -o ${output_bin}

    #Add the SVN (Security Version Number ) to header
    echo ${PFM_SVN} | dd of=${SECBOOT_IMAGES_DIR}/pfm.bin bs=1 seek=4 count=1 conv=notrunc

    # sign the PFM region
    ${SIGN_UTILITY} -c ${SECBOOT_CFG_DIR}/${pfmconfig_xml} -o ${SECBOOT_IMAGES_DIR}/${pfm_signed_bin} ${SECBOOT_IMAGES_DIR}/pfm.bin -v

    # Add the signed PFM to rom image
    dd bs=1k conv=notrunc seek=${PFM_OFFSET_PAGE} if=${SECBOOT_IMAGES_DIR}/${pfm_signed_bin} of=${SECBOOT_IMAGES_DIR}/${output_bin}

    # Add the signed PFM  to full rom image @0x04080000
    dd bs=1k conv=notrunc seek=${PFM_OFFSET_PAGE_B} if=${SECBOOT_IMAGES_DIR}/${pfm_signed_bin} of=${SECBOOT_IMAGES_DIR}/${output_bin}

    # Create unsigned BMC update capsule(SPL and without SPL) - append with 1. pfm_signed, 2. pbc, 3. bmc compressed
    dd if=${SECBOOT_IMAGES_DIR}/${pfm_signed_bin} bs=1k >> ${SECBOOT_IMAGES_DIR}/${unsigned_cap_bin}
    dd if=${SECBOOT_IMAGES_DIR}/${pfm_signed_bin} bs=1k >> ${SECBOOT_IMAGES_DIR}/${unsigned_cap_spl_bin}

    dd if=${SECBOOT_IMAGES_DIR}/pbc.bin bs=1k >> ${SECBOOT_IMAGES_DIR}/${unsigned_cap_spl_bin}
    # Skip the  RoT image flashing set the 2 Byte.
    dd if=/dev/zero of=${SECBOOT_IMAGES_DIR}/pbc.bin bs=1 seek=128 count=2 conv=notrunc
    dd if=/dev/zero of=${SECBOOT_IMAGES_DIR}/pbc.bin bs=1 seek=4224 count=2 conv=notrunc
    dd if=${SECBOOT_IMAGES_DIR}/pbc.bin bs=1k >> ${SECBOOT_IMAGES_DIR}/${unsigned_cap_bin}

    dd if=${SECBOOT_IMAGES_DIR}/bmc_compressed.bin bs=1k >> ${SECBOOT_IMAGES_DIR}/${unsigned_cap_spl_bin}
    # Skip the SPL image part from the current compressed image and create bmc capsule
    dd if=${SECBOOT_IMAGES_DIR}/bmc_compressed.bin skip=64 bs=1k >> ${SECBOOT_IMAGES_DIR}/${unsigned_cap_bin}

    # Sign the BMC update capsule
    ${SIGN_UTILITY} -c ${SECBOOT_CFG_DIR}/${bmcconfig_xml} -o ${SECBOOT_IMAGES_DIR}/${signed_cap_bin} ${SECBOOT_IMAGES_DIR}/${unsigned_cap_bin} -v
    ${SIGN_UTILITY} -c ${SECBOOT_CFG_DIR}/${bmcconfig_spl_xml} -o ${SECBOOT_IMAGES_DIR}/${signed_cap_spl_bin} ${SECBOOT_IMAGES_DIR}/${unsigned_cap_spl_bin} -v

    # Rename all Secure boot output images by appending date and time, so that they don't meddle with subsequent call to this function.
    mv ${SECBOOT_IMAGES_DIR}/${pfm_signed_bin}         ${SECBOOT_IMAGES_DIR}/pfm_signed${bld_suffix}-${DATETIME}.bin
    mv ${SECBOOT_IMAGES_DIR}/${unsigned_cap_bin}       ${SECBOOT_IMAGES_DIR}/bmc_unsigned_cap${bld_suffix}-${DATETIME}.bin
    mv ${SECBOOT_IMAGES_DIR}/${unsigned_cap_align_bin} ${SECBOOT_IMAGES_DIR}/bmc_unsigned_cap${bld_suffix}-${DATETIME}.bin_aligned

    # Create SPL and without SPL bmc capsule.
    mv ${SECBOOT_IMAGES_DIR}/${signed_cap_spl_bin}         ${SECBOOT_IMAGES_DIR}/bmc_signed_cap_spl${bld_suffix}-${DATETIME}.bin
    mv ${SECBOOT_IMAGES_DIR}/${signed_cap_bin}         ${SECBOOT_IMAGES_DIR}/bmc_signed_cap${bld_suffix}-${DATETIME}.bin

    mv ${SECBOOT_IMAGES_DIR}/${output_bin}             ${SECBOOT_IMAGES_DIR}/image-mtd-pfr${bld_suffix}-${DATETIME}.bin
    # Append date and time to all 'pfr_image.py' output binaries.
    mv ${SECBOOT_IMAGES_DIR}/pfm.bin            ${SECBOOT_IMAGES_DIR}/pfm${bld_suffix}-${DATETIME}.bin
    mv ${SECBOOT_IMAGES_DIR}/pfm.bin_aligned    ${SECBOOT_IMAGES_DIR}/pfm${bld_suffix}-${DATETIME}.bin_aligned
    mv ${SECBOOT_IMAGES_DIR}/pbc.bin            ${SECBOOT_IMAGES_DIR}/pbc${bld_suffix}-${DATETIME}.bin
    mv ${SECBOOT_IMAGES_DIR}/bmc_compressed.bin ${SECBOOT_IMAGES_DIR}/bmc_compressed${bld_suffix}-${DATETIME}.bin

    # Use relative links. The build process removes some of the build
    # artifacts and that makes fully qualified pathes break. Relative links
    # work because of the 'cd "${SECBOOT_IMAGES_DIR}"' at the start of this section.
    ln -sf image-mtd-pfr${bld_suffix}-${DATETIME}.bin  ${SECBOOT_IMAGES_DIR}/image-mtd-pfr${bld_suffix}.bin
    ln -sf image-mtd-pfr${bld_suffix}-${DATETIME}.bin  ${SECBOOT_IMAGES_DIR}/OBMC${bld_suffix}-${@ do_get_version(d)}-pfr-full.ROM
    ln -sf bmc_signed_cap_spl${bld_suffix}-${DATETIME}.bin ${SECBOOT_IMAGES_DIR}/bmc_signed_cap_spl${bld_suffix}.bin
    ln -sf bmc_signed_cap_spl${bld_suffix}-${DATETIME}.bin ${SECBOOT_IMAGES_DIR}/OBMC${bld_suffix}-${@ do_get_version(d)}-pfr-oob-spl.bin
    ln -sf bmc_signed_cap${bld_suffix}-${DATETIME}.bin ${SECBOOT_IMAGES_DIR}/bmc_signed_cap${bld_suffix}.bin
    ln -sf bmc_signed_cap${bld_suffix}-${DATETIME}.bin ${SECBOOT_IMAGES_DIR}/OBMC${bld_suffix}-${@ do_get_version(d)}-pfr-oob.bin
}

# Network access from task are disabled by default on Yocto 3.5
# Enable it explicitely so that image signing can be performed using external
# signing server
do_image_secboot[network] = "1"
do_image_secboot () {
    # Secure boot image, additional build components information suffix.
    local bld_suffix=""

    bbplain "Generating Intel Secure boot compliant BMC image for '${PRODUCT_GENERATION}'"

    bbplain "Build Version = ${build_version}"
    bbplain "Build Number = ${build_number}"
    bbplain "Build Hash = ${build_hash}"
    bbplain "Build SHA = ${SHA_NAME}"

    mkdir -p "${SECBOOT_IMAGES_DIR}"
    cd "${SECBOOT_IMAGES_DIR}"

    # First, Build default image.
    bld_suffix=""
    do_image_secboot_internal
    generate_otp_capsule
}

# Include 'do_image_secboot_internal' in 'vardepsexclude';Else Taskhash mismatch error will occur.
do_image_secboot[vardepsexclude] += "do_image_secboot_internal DATE DATETIME BUILD_SEGD"
do_image_secboot[vardepsexclude] += "IPMI_MAJOR IPMI_MINOR IPMI_AUX13 IPMI_AUX14 IPMI_AUX15 IPMI_AUX16"
do_image_secboot[depends] += " \
                         obmc-intel-pfr-image-native:do_populate_sysroot \
                         intel-pfr-signing-utility-native:do_populate_sysroot \
                         external-signing-utility-native:do_populate_sysroot \
                         otp-capsule-generator-native:do_populate_sysroot \
                        "

python() {

    types = d.getVar('IMAGE_FSTYPES', True).split()

    if 'intel-secboot' in types:

        bld_ver1 = d.getVar('IPMI_MAJOR', True)
        bld_ver1 = int(bld_ver1) << 8

        bld_ver2 = d.getVar('IPMI_MINOR', True)
        bld_ver2 = int(bld_ver2)

        bld_ver = bld_ver1 | bld_ver2
        d.setVar('build_version', str(bld_ver))

        bld_num = d.getVar('IPMI_AUX13', True)

        d.setVar('build_number', bld_num)

        bld_hash1 = d.getVar('IPMI_AUX14', True)
        bld_hash2 = d.getVar('IPMI_AUX15', True)
        bld_hash3 = d.getVar('IPMI_AUX16', True)

        bld_hash1 = int(bld_hash1, 16)
        bld_hash2 = int(bld_hash2, 16)
        bld_hash3 = int(bld_hash3, 16)

        bld_hash = bld_hash3 << 16
        bld_hash |= bld_hash2 << 8
        bld_hash |= bld_hash1

        d.setVar('build_hash', str(bld_hash))

        bb.build.addtask(# task, depends_on_task, task_depends_on, d )
                'do_image_secboot',
                'do_build',
                'do_generate_auto', d)
}

