IMAGE_POSTPROCESS_COMMAND:append = " do_copy_fvp;"

BASEDIR = "${THISDIR}/../../.."
RUNFVP_DIR = "${BASEDIR}/meta-arm"

do_copy_fvp[depends] = "fvp-base-a-aem-native:do_install"

do_copy_fvp() {
  rm -rf ${DEPLOY_DIR_IMAGE}/utilities/fvp/scripts
  install -d ${DEPLOY_DIR_IMAGE}/utilities/fvp/scripts
  cp ${RUNFVP_DIR}/scripts/runfvp ${DEPLOY_DIR_IMAGE}/utilities/fvp/scripts/

  rm -rf ${DEPLOY_DIR_IMAGE}/utilities/fvp/meta-arm
  install -d ${DEPLOY_DIR_IMAGE}/utilities/fvp/meta-arm/lib/fvp
  cp -r ${RUNFVP_DIR}/meta-arm/lib/fvp/*.py ${DEPLOY_DIR_IMAGE}/utilities/fvp/meta-arm/lib/fvp/
}
