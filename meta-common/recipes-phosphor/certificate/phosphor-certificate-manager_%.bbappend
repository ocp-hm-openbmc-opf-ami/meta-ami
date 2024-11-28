FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

#PACKAGECONFIG:append = " asd-cert"
#PACKAGECONFIG[asd-cert] = "-Dconfig-asd=enabled,-Dconfig-asd=disabled"
PACKAGECONFIG:append = " authority-cert"


SRC_URI += " \
	    file://0001-renew-rekey.patch \
	    file://0002-asd-certificate.patch \
            file://0003-throw-CertificateExists-error.patch \
            file://0004-Throws-an-error-if-the-private-key-file-is-not-found.patch \
	    file://0005-certificate-Chain-support.patch \
	    file://0006-Add-enhancement-for-certificate-errors.patch \
	    file://0007-Removed-PrivateKey-Validation.patch \
           "
