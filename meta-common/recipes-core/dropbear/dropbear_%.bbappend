FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI =+ "file://dropbear.default  \
            file://dropbear@.service "
SRC_URI =+ "file://0006-Add-ECC-macro-guard-insecure-cipher-option-and-stric.patch "

do_configure:append() {
        echo "#define DROPBEAR_CURVE25519 0" >> ${B}/localoptions.h
        echo "#define DROPBEAR_DH_GROUP14_SHA256 0" >> ${B}/localoptions.h
        echo "#define DROPBEAR_KEXGUESS2 0" >> ${B}/localoptions.h
        echo "#define DROPBEAR_ED25519 0" >> ${B}/localoptions.h
        echo "#define DROPBEAR_RSA 0" >> ${B}/localoptions.h
        echo "#define DROPBEAR_AES128 0" >> ${B}/localoptions.h
        echo "#define DROPBEAR_SHA2_256_HMAC 0" >> ${B}/localoptions.h
        echo "#define DROPBEAR_ECC_256 0" >> ${B}/localoptions.h
        echo "#define OPENSSH_STRICT_KEX 0" >> ${B}/localoptions.h
        echo "#define DROPBEAR_SNTRUP761_OPENSSL 0" >> ${B}/localoptions.h
        echo "#define DROPBEAR_ECC 1" >> ${B}/localoptions.h
}
