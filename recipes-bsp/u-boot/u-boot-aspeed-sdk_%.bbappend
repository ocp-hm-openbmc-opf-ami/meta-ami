FILESEXTRAPATHS:append:intel-ast2600:= "${THISDIR}/files:"

SRC_URI:append:intel-ast2600 = " \
    file://spl.cfg \
    file://ast2600_a3.json \
    "

#Enable ASPEED SOC Secure Boot
SOCSEC_SIGN_ENABLE = "0"

SOCSEC_SIGN_KEY = "${WORKDIR}/keys/SIG_RSA_KEY2_private.pem"
SOCSEC_SIGN_ALGO = "RSA2048_SHA256"
OTPTOOL_CONFIGS = "${WORKDIR}/ast2600_a3.json"
OTPTOOL_KEY_DIR = "${WORKDIR}/keys/"

SOCSEC_SIGN_EXTRA_OPTS = "--rsa_key_order=little"

do_deploy:prepend() {
        # otptool needs access to the public and private socsec signing keys in the keys/ directory. uncomment if SOCSEC enabled
        # openssl rsa -in ${SOCSEC_SIGN_KEY} -pubout > ${WORKDIR}/keys/SIG_RSA_KEY2_public.pem
}

