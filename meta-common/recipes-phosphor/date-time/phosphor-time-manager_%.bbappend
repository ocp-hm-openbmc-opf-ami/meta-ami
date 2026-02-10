FILESEXTRAPATHS:append := "${THISDIR}/${PN}:"

DBUS_SERVICE:${PN} += "xyz.openbmc_project.NTPSec.Manager.service"
                                                                                                                                                                                    
SRC_URI += " \
           file://0001-Added-support-for-Secure-NTP.patch \
           file://0002-Fix-for-NTPsec-persistent-across-reboots.patch \
           file://0003-Handle-Error-for-NTPSec-configuration.patch \
           "
