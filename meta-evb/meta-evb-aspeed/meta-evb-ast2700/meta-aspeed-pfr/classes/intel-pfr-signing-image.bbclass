DEPENDS:append = " obmc-pfr-image-native \
                   intel-pfr-signing-utility-native \
                 "

IMAGE_INSTALL:append = " packagegroup-aspeed-pfr-apps \
                         packagegroup-intel-pfr-apps \
                       "

do_generate_static:append() {
    bb.build.exec_func("do_generate_signed_pfr_image", d)
}

# PFR images directory
PFR_DEPLOY_IMAGES_DIR = "${IMGDEPLOYDIR}/pfr_images"
PFR_IMAGES_DIR = "${S}/pfr_images"

# PFR image generation script directory
PFR_SCRIPT_DIR = "${STAGING_DIR_NATIVE}${bindir}"

# PFR image config directory
PFR_CFG_DIR = "${STAGING_DIR_NATIVE}${datadir}/pfrconfig"

# Temporary hardcode
PFR_PLATFORM ?= "obmc"
PFR_SVN ?= "1"
PFR_BKC_VER ?= "1"
PFR_BUILD_VER_MAJ ?= "1"
PFR_BUILD_VER_MIN ?= "0"
PFR_BUILD_NUM ?= "565566"
# 1 = SHA256
# 2 = SHA384
# 3 = LMS384
# 4 = LMS256
PFR_SHA ?= "2"

do_generate_signed_pfr_image(){
    local manifest_json=${PFR_MANIFEST}
    local pfmconfig_xml=""
    local bmcconfig_xml=""
    local pfm_signed_bin="pfm_signed.bin"
    local signed_cap_bin="bmc_signed_cap.bin"
    local unsigned_cap_bin="bmc_unsigned_cap.bin"
    local unsigned_cap_align_bin="bmc_unsigned_cap.bin_aligned"
    local output_bin="image-mtd-pfr"
    local SIGN_UTILITY=${PFR_SCRIPT_DIR}/intel-pfr-signing-utility

    if [ "${PFR_SHA}" = "1" ]; then
        pfmconfig_xml="pfm_config.xml"
        bmcconfig_xml="bmc_config.xml"
        PFR_SHA_TYPE=1
    elif [ "${PFR_SHA}" = "2" ]; then
        pfmconfig_xml="pfm_config_secp384r1.xml"
        bmcconfig_xml="bmc_config_secp384r1.xml"
        PFR_SHA_TYPE=2
    elif [ "${PFR_SHA}" = "3" ]; then
        pfmconfig_xml="pfm_config_lms384.xml"
        bmcconfig_xml="bmc_config_lms384.xml"
        SIGN_UTILITY=${PFR_SCRIPT_DIR}/intel-pfr-signing-utility_lms
        PFR_SHA_TYPE=2
    elif [ "${PFR_SHA}" = "4" ]; then
        pfmconfig_xml="pfm_config_lms256.xml"
        bmcconfig_xml="bmc_config_lms256.xml"
        SIGN_UTILITY=${PFR_SCRIPT_DIR}/intel-pfr-signing-utility_lms
        PFR_SHA_TYPE=1
    fi

    rm -rf ${PFR_IMAGES_DIR}
    mkdir -p ${PFR_IMAGES_DIR}
    cd ${PFR_IMAGES_DIR}

    # Assemble the flash image
    mk_empty_image ${PFR_IMAGES_DIR}/image-mtd ${PFR_IMAGE_SIZE}

    dd bs=1k conv=notrunc seek=0 \
        if=${IMGDEPLOYDIR}/${IMAGE_NAME}.static.mtd \
        of=${PFR_IMAGES_DIR}/image-mtd

    python3 ${PFR_SCRIPT_DIR}/pfr_image.py -m ${PFR_CFG_DIR}/${manifest_json} \
        -p ${PFR_PLATFORM} \
        -i ${PFR_IMAGES_DIR}/image-mtd \
        -j ${PFR_BUILD_VER_MAJ} \
        -n ${PFR_BUILD_VER_MIN} \
        -b ${PFR_BUILD_NUM} \
        -v ${PFR_BKC_VER} \
        -s ${PFR_SVN} \
        -a ${PFR_SHA_TYPE} \
        -o ${output_bin}

    # sign the PFM region
    ${SIGN_UTILITY} -c ${PFR_CFG_DIR}/${pfmconfig_xml} -o ${PFR_IMAGES_DIR}/${pfm_signed_bin} ${PFR_IMAGES_DIR}/obmc-pfm.bin -v

    # Parsing and Verifying the PFM
    echo "Parsing and Verifying the PFM"
    ${SIGN_UTILITY} -p ${PFR_IMAGES_DIR}/${pfm_signed_bin} -c ${PFR_CFG_DIR}/${pfmconfig_xml}
    if [ $(${SIGN_UTILITY} -p ${PFR_IMAGES_DIR}/${pfm_signed_bin} -c ${PFR_CFG_DIR}/${pfmconfig_xml} 2>&1 | grep "ERR" | wc -c) -gt 0 ]; then
        bbfatal "Verify the PFM failed."
    fi

    # Add the signed PFM to rom image
    dd bs=1k conv=notrunc seek=${PFM_OFFSET_PAGE} \
        if=${PFR_IMAGES_DIR}/${pfm_signed_bin} \
        of=${PFR_IMAGES_DIR}/${output_bin}

    # Create unsigned BMC update capsule - append with 1. pfm_signed, 2. pbc, 3. bmc compressed
    dd if=${PFR_IMAGES_DIR}/${pfm_signed_bin} bs=1k >> ${PFR_IMAGES_DIR}/${unsigned_cap_bin}

    dd if=${PFR_IMAGES_DIR}/obmc-pbc.bin bs=1k >> ${PFR_IMAGES_DIR}/${unsigned_cap_bin}

    dd if=${PFR_IMAGES_DIR}/obmc-bmc_compressed.bin bs=1k >> ${PFR_IMAGES_DIR}/${unsigned_cap_bin}

    # Sign the BMC update capsule
    ${SIGN_UTILITY} -c ${PFR_CFG_DIR}/${bmcconfig_xml} -o ${PFR_IMAGES_DIR}/${signed_cap_bin} ${PFR_IMAGES_DIR}/${unsigned_cap_bin} -v

    # Parsing and Verifying the BMC update capsule
    echo "Parsing and Verifying the BMC update capsule"
    ${SIGN_UTILITY} -p ${PFR_IMAGES_DIR}/${signed_cap_bin} -c ${PFR_CFG_DIR}/${bmcconfig_xml}
    if [ $(${SIGN_UTILITY} -p ${PFR_IMAGES_DIR}/${signed_cap_bin} -c ${PFR_CFG_DIR}/${bmcconfig_xml} 2>&1 | grep "ERR" | wc -c) -gt 0 ]; then
        bbfatal "Verify the BMC update capsule failed."
    fi

    # Add the signed bmc update capsule to full rom image
    dd bs=1k conv=notrunc seek=${RC_IMAGE_PAGE} \
        if=${PFR_IMAGES_DIR}/${signed_cap_bin} \
        of=${PFR_IMAGES_DIR}/${output_bin}

    # deploy pfr images
    if [ -d ${PFR_DEPLOY_IMAGES_DIR} ]; then
        rm -rf ${PFR_DEPLOY_IMAGES_DIR}
    fi

    install -d ${PFR_DEPLOY_IMAGES_DIR}
    install -m 0644 ${PFR_IMAGES_DIR}/*.bin ${PFR_DEPLOY_IMAGES_DIR}/.
    install -m 0644 ${PFR_IMAGES_DIR}/*.bin_aligned ${PFR_DEPLOY_IMAGES_DIR}/.
    install -m 0644 ${PFR_IMAGES_DIR}/${output_bin} ${PFR_DEPLOY_IMAGES_DIR}/.
}
