SUMMARY = "https_dns_proxy: A DNS over HTTPS proxy server"
DESCRIPTION = "https_dns_proxy is a light-weight DNS<-->HTTPS, non-caching translation proxy for the RFC 8484 DNS-over-HTTPS standard. Using DNS over HTTPS makes eavesdropping and spoofing of DNS traffic between you and the HTTPS DNS provider (Google/Cloudflare) much less likely. It receives regular (UDP) DNS requests and issues them via DoH."
HOMEPAGE = "https://github.com/aarond10/https_dns_proxy"
LICENSE = "MIT"
#DEPENDS = ""
LIC_FILES_CHKSUM = "file://LICENSE;md5=b213ece8dac27def21a4514fd537988a"
#SRCREV = "2cf67e30a797fbec1c7e4bbdb79ab6174fdd4bfc"
#SRC_URI = "git://github.com/aarond10/https_dns_proxy.git;branch=main;protocol=https"
SRC_URI = "git://github.com/aarond10/https_dns_proxy.git;protocol=https;branch=master"
SRCREV = "484bd153bb85a51df1c5bede1b091be76537e0a7"
S = "${WORKDIR}/git"
inherit cmake

#DEPENDS += "clang-tools-extra"
DEPENDS += "c-ares curl libev"


do_install:append() {
    install -d ${D}${bindir}
    install -m 0755 ${B}/https_dns_proxy  ${D}${bindir}/https_dns_proxy

    install -d ${D}${systemd_system_unitdir}
    install -m 0644 ${B}/https_dns_proxy.service ${D}${systemd_system_unitdir}
}

FILES:${PN} += "https_dns_proxy"
FILES:${PN} += "${systemd_unitdir}/system/https_dns_proxy.service"
FILES:${PN} += "/usr/lib"
FILES:${PN} += "/usr/lib/systemd"
FILES:${PN} += "/usr/lib/systemd/system"
