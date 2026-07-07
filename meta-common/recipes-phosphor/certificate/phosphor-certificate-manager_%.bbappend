FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

#PACKAGECONFIG:append = " asd-cert"
#PACKAGECONFIG[asd-cert] = "-Dconfig-asd=enabled,-Dconfig-asd=disabled"
PACKAGECONFIG:append = " authority-cert"


SRC_URI += " \
			file://0001-renew-rekey.patch \
			file://0002-asd-certificate-LF.patch \
			file://0003-throw-CertificateExists-error-LF.patch \
            file://0004-Throws-an-error-if-the-private-key-file-is-not-found.patch \
			file://0005-certificate-Chain-support-LF.patch \
			file://0006-Add-enhancement-for-certificate-errors.patch \
			file://0007-Removed-PrivateKey-Validation.patch \
            file://0008-Added-feature-for-Certificate-replacement.patch \
			file://0009-Fix-For-rekey-rekey-LF.patch \
            file://0010-Add-new-certificate-data-fields-support.patch \
            file://0012-populate-properties-from-PEM-chain.patch \
			file://0013-High-Coverity-fix-CM-4-phosphor-certificate-manager.patch \
			file://0014-Response-Time-Error.patch \
			file://0015-clang-format-19-LF.patch \
			"
