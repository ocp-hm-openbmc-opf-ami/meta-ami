FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

#PACKAGECONFIG:append = " asd-cert"
#PACKAGECONFIG[asd-cert] = "-Dconfig-asd=enabled,-Dconfig-asd=disabled"

#SYSTEMD_SERVICE:${PN} = " \
#        ${@bb.utils.contains('PACKAGECONFIG', 'asd', 'phosphor-certificate-manager@asd.service', '', d)} \
#        "

SRC_URI += " \
	    file://0001-renew-rekey.patch \
	    file://0002-asd-certificate.patch \
            file://0003-throw-CertificateExists-error.patch \
            file://0004-Throws-an-error-if-the-private-key-file-is-not-found.patch \
           "
