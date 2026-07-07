DESCRIPTION = "Generate Secure Boot image for Intel Bmc"
LICENSE = "MIT"
PACKAGE_ARCH = "${MACHINE_ARCH}"

PR = "r0"

DEPENDS = " \
    socsec-native \
    intel-pfr-signing-utility-native \
    secureboot-config-native \
    virtual/bootloader \
    virtual/kernel \
    "

do_patch[noexec] = "1"
do_configure[noexec] = "1"
do_compile[noexec] = "1"
do_install[noexec] = "1"

inherit python3native deploy


# Image composition
UBOOT_SPL_IMAGE ?= "u-boot-spl.bin"
SUBOOT_SPL_IMAGE ?= "s_${UBOOT_SPL_IMAGE}"

ASPEED_SECURE_BOOT_CONFIG_ROOT_DIR ?= "${STAGING_DATADIR_NATIVE}"

OUTPUT_IMAGE_DIR ?= "${S}/output"
SOURCE_IMAGE_DIR ?= "${S}/source"
REVISION_ID = "1"

print_otp_image() {
    if [ "${OTP_CONFIG}" != "" ]; then
        echo "Printing OTP Image ..."
        otptool \
        print \
        ${OUTPUT_IMAGE_DIR}/otp_image/otp-all.image

        if [ $? -ne 0 ]; then
            echo "Printed OTP image failed."
            exit 1
        fi
   fi
}

create_otp_image() {
    if [ "${OTP_CONFIG}" != "" ]; then
        echo "Generating OTP Image ..."
        echo "OTP_CONFIG=${OTP_CONFIG}"
        echo "KEY_DIR=${KEY_DIR}"

        otptool \
        make_otp_image \
        ${OTP_CONFIG} \
        --key_folder ${KEY_DIR} \
        --user_data_folder ${STAGING_DATADIR_NATIVE}/secureboot-config/${ASPEED_SECURE_BOOT_TARGET}/security/data \
        --output_folder ${OUTPUT_IMAGE_DIR}/otp_image

        if [ $? -ne 0 ]; then
            echo "Generated OTP image failed."
            exit 1
        fi
   fi
}

create_secure_boot_image() {
    echo "Generating ROT Image ..."
    echo "ROT_ALGORITHM=${ROT_ALGORITHM}"
    echo "ROT_SIGN_KEY=${ROT_SIGN_KEY}"
    echo "SIGNING_HELPER=${SIGNING_HELPER}"
    echo "SIGNING_HELPER_WITH_FILES=${SIGNING_HELPER_WITH_FILES}"
    echo "AES_KEY_IN_OTP=${AES_KEY_IN_OTP}"
    echo "KEY_ORDER=${KEY_ORDER}"
    echo "AES_KEY=${AES_KEY}"
    echo "RSA_AES_KEY=${RSA_AES_KEY}"
    #KEY_ORDER="little"

    if [ "${AES_KEY_IN_OTP}" == "1" ]; then
        socsec \
        make_secure_bl1_image \
        --algorithm ${ROT_ALGORITHM} \
        --bl1_image ${SOURCE_IMAGE_DIR}/${UBOOT_SPL_IMAGE} \
        --output ${OUTPUT_IMAGE_DIR}/${SUBOOT_SPL_IMAGE} \
        --rsa_sign_key ${ROT_SIGN_KEY} \
        --rsa_key_order ${KEY_ORDER} \
        --key_in_otp \
        --aes_key ${AES_KEY} \
        --rsa_aes ${RSA_AES_KEY} \
        --stack_intersects_verification_region "false" \
        --signing_helper ${SIGNING_HELPER} \
        --signing_helper_with_files ${SIGNING_HELPER_WITH_FILES} \
        --revision_id ${REVISION_ID}
    else
        socsec \
        make_secure_bl1_image \
        --algorithm ${ROT_ALGORITHM} \
        --bl1_image ${SOURCE_IMAGE_DIR}/${UBOOT_SPL_IMAGE} \
        --output ${OUTPUT_IMAGE_DIR}/${SUBOOT_SPL_IMAGE} \
        --rsa_sign_key ${ROT_SIGN_KEY} \
        --rsa_key_order ${KEY_ORDER} \
        --aes_key ${AES_KEY} \
        --rsa_aes ${RSA_AES_KEY} \
        --stack_intersects_verification_region "false" \
        --signing_helper ${SIGNING_HELPER} \
        --signing_helper_with_files ${SIGNING_HELPER_WITH_FILES} \
        --revision_id ${REVISION_ID}
    fi

    if [ $? -ne 0 ]; then
        echo "Generated ROT image failed."
        exit 1
    fi

    if [ "${OTP_CONFIG}" != "" ]; then
        echo "Verifying OTP Image ..."
        socsec verify --sec_image ${OUTPUT_IMAGE_DIR}/${SUBOOT_SPL_IMAGE} --otp_image ${OUTPUT_IMAGE_DIR}/otp_image/otp-all.image

         if [ $? -ne 0 ]; then
            echo "Verified OTP image failed."
            exit 1
        fi
    fi
}

do_deploy () {
    unset ROOT_DIR
    export ROOT_DIR="${ASPEED_SECURE_BOOT_CONFIG_ROOT_DIR}"
    if [ -z ${SPL_BINARY} ]; then
        echo "To support ASPEED secure boot, u-boot should support spl."
        exit 1
    fi

    if [ -f ${ASPEED_SECURE_BOOT_CONFIG} ]; then
        source ${ASPEED_SECURE_BOOT_CONFIG}
    else
        bbwarn "User secure boot config not found!, ${ASPEED_SECURE_BOOT_CONFIG}"

        if [ ! -f ${STAGING_DATADIR_NATIVE}/secureboot-config/${ASPEED_SECURE_BOOT_TARGET}/${ASPEED_SECURE_BOOT_CONFIG} ]; then
            echo "aspeed secure boot config not found!, ${STAGING_DATADIR_NATIVE}/secureboot-config/${ASPEED_SECURE_BOOT_TARGET}/${ASPEED_SECURE_BOOT_CONFIG}"
            exit 1
        fi

        . ${STAGING_DATADIR_NATIVE}/secureboot-config/${ASPEED_SECURE_BOOT_TARGET}/${ASPEED_SECURE_BOOT_CONFIG}
        bbwarn "Using an aspeed insecure config signing key!, ${STAGING_DATADIR_NATIVE}/secureboot-config/${ASPEED_SECURE_BOOT_TARGET}/${ASPEED_SECURE_BOOT_CONFIG}"
    fi

    if [ -d ${SOURCE_IMAGE_DIR} ]; then
        rm -rf ${SOURCE_IMAGE_DIR}
    fi

    if [ -d ${OUTPUT_IMAGE_DIR} ]; then
        rm -rf ${OUTPUT_IMAGE_DIR}
    fi
    
    install -d ${SOURCE_IMAGE_DIR}
    install -d ${OUTPUT_IMAGE_DIR}

    # Install u-boot-spl image into source directory.
    install -m 0644 ${DEPLOY_DIR_IMAGE}/${UBOOT_SPL_IMAGE} ${SOURCE_IMAGE_DIR}

    create_otp_image
    print_otp_image
    create_secure_boot_image

    # Deploy OTP image
    install -d ${DEPLOYDIR}
    install -d ${DEPLOYDIR}/otp_image
    install -m 0644 ${OUTPUT_IMAGE_DIR}/otp_image/* ${DEPLOYDIR}/otp_image/.

    # Deploy ROT image
    install -m 0644 ${OUTPUT_IMAGE_DIR}/*.bin ${DEPLOYDIR}/.

}

do_deploy[depends] += " \
    virtual/kernel:do_deploy \
    virtual/bootloader:do_deploy \
    "

addtask deploy before do_build after do_compile
