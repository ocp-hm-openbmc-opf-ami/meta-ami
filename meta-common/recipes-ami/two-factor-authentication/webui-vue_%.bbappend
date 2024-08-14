FILESEXTRAPATHS:append := "${THISDIR}/${PN}:"

#DEPENDS += "web-two-factor-authentication"

do_compile:prepend() {
  # Copy TFA macro sources to webui Directory
  if ${@bb.utils.contains('IMAGE_INSTALL',' google-authenticator-libpam','true','false',d)}; then
  echo "\nVUE_APP_TFA="true"" >> ${S}/.env.intel
  fi
}
