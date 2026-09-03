fvp_link_binaries:append(){
  do_copy_fvp
}

do_copy_fvp() {
  rm -rf ${DEPLOY_DIR_IMAGE}/utilities/fvp
  install -d ${DEPLOY_DIR_IMAGE}/utilities/fvp
  cp -r ${D}${FVPDIR}/../../../../ ${DEPLOY_DIR_IMAGE}/utilities/fvp/
}
# Skip sstate creation for CI
SSTATE_SKIP_CREATION = "1"