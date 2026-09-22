#Look in our local files/ dir first
FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

# Name of the env file (without suffix)
UBOOT_ENV = "custom-bmc-env"

UBOOT_CONFIG_FRAGMENTS += "defconfig-fragment.cfg"

# Stage the text env file into WORKDIR during do_fetch/do_unpack
SRC_URI += " file://custom-bmc-env.txt"
SRC_URI += " file://defconfig-fragment.cfg"

# Ensure u-boot's env handling is active (harmless if base recipe already does this)
inherit uboot-config


# Custom task to copy into the build directory after unpack
do_copy_custom_env() {
  # Make sure the build dir exists
  install -d ${B}

  src="${UNPACKDIR}/custom-bmc-env.txt"
  if [ ! -f "${src}" ]; then
        bbfatal "custom-bmc-env.txt not found in UNPACKDIR (${UNPACKDIR}). Check FILESPATH/SRC_URI."
  fi

  install -m 0644 "${src}" "${B}/custom-bmc-env.txt"
}

# Register the task to run after unpack and before configure
addtask copy_custom_env after do_unpack before do_configure

# Also deploy the file as part of do_deploy
do_deploy:append() {
  install -d ${DEPLOYDIR}
  install -m 0644 ${B}/custom-bmc-env.txt ${DEPLOYDIR}/custom-bmc-env.txt
}


#do_configure:append () {
#    cp ${WORKDIR}/custom-bmc-env.txt ${S}/custom-bmc-env.txt
#}
#
### Optional: some vendor recipes look into ${S}; place it there too
#do_configure:append () {
## Try WORKDIR root, then UNPACKDIR (sources-unpack), then layer path
#  src="${WORKDIR}/${UBOOT_ENV}.${UBOOT_ENV_SUFFIX}"
#  [ -f "$src" ] ||
#  src="${UNPACKDIR}/${UBOOT_ENV}.${UBOOT_ENV_SUFFIX}"
#  [ -f "$src" ] ||
#  src="${THISDIR}/files/${UBOOT_ENV}.${UBOOT_ENV_SUFFIX}"
#  cp "$src" "${S}/" || true
#  cp "$src" "${B}/" || true
#}
#
## Put the env file in ${B} *right before* install/deploy so uboot-config can find it
#do_install:prepend () {
#  src="${WORKDIR}/${UBOOT_ENV}.${UBOOT_ENV_SUFFIX}"
#  if [ ! -f "$src" ]; then
#     # On your build the file is staged here:
#     src="${UNPACKDIR}/${UBOOT_ENV}.${UBOOT_ENV_SUFFIX}"
#  fi
#  if [ ! -f "$src" ]; then
#     # Absolute fallback to layer path (useful if sstate skipped unpack)
#     src="${THISDIR}/files/${UBOOT_ENV}.${UBOOT_ENV_SUFFIX}"
#  fi
#  install -m 0644 "$src" "${B}/"
#}
#
## Make sure our prepend runs after the file has been unpacked to WORKDIR
#do_install[deptask] += "do_unpack"
