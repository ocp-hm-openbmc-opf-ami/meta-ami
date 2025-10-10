SUMMARY = "the Apache Kafka C/C++ client library"
HOMEPAGE = "http://apr.apache.org/"
SECTION = "libs"

LICENSE = "BSD-2-Clause"
LIC_FILES_CHKSUM = "file://LICENSE;md5=40b04809b5d6f648f20f45143cbcb1ad"

DEPENDS = "zlib openssl zstd"

inherit cmake

FILES:${PN} += "${datadir}"
EXTRA_OECMAKE += "-DRDKAFKA_BUILD_EXAMPLES=OFF -DRDKAFKA_BUILD_TESTS=OFF"

BRANCH = "master"
SRCREV = "e03d3bb91ed92a38f38d9806b8d8deffe78a1de5"
SRC_URI = "git://github.com/edenhill/librdkafka;protocol=ssh;branch=${BRANCH}"

# Add support for setting TLSv1.3 ciphersuites
SRC_URI += " \
    file://0001-Add-support-for-setting-TLSv1.3-ciphers.patch \
"

S = "${WORKDIR}/git"
