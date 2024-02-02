FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

#PACKAGECONFIG:append = " asd-cert"
#PACKAGECONFIG[asd-cert] = "-Dconfig-asd=enabled,-Dconfig-asd=disabled"

#SYSTEMD_SERVICE:${PN} = " \
#        ${@bb.utils.contains('PACKAGECONFIG', 'asd', 'phosphor-certificate-manager@asd.service', '', d)} \
#        "

SRC_URI += " \
	    file://0001-renew-rekey.patch \
           "