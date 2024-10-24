SUMMARY = "Prebuilt OpenJDK for Java 11 offered by Adoptium"
HOMEPAGE = "https://adoptium.net"
LICENSE = "GPL-2.0-with-classpath-exception"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/GPL-2.0-with-classpath-exception;md5=6133e6794362eff6641708cfcc075b80"

JVM_CHECKSUM = "191baa2e052627614022171400a917d28f0987dc54da48aaf07b06f552bb9884"

API_RELEASE_NAME = "jdk-${PV}"
API_OS = "linux"
API_ARCH = "x64"
API_IMAGE_TYPE = "jdk"
API_JVM_IMPL = "hotspot"
API_HEAP_SIZE ?= "normal"
API_VENDOR = "eclipse"

SRC_URI = "https://api.adoptium.net/v3/binary/version/${API_RELEASE_NAME}/${API_OS}/${API_ARCH}/${API_IMAGE_TYPE}/${API_JVM_IMPL}/${API_HEAP_SIZE}/${API_VENDOR};downloadfilename=${BPN}-${API_ARCH}-${PV}.tar.gz;subdir=${BPN}-${PV};striplevel=1"
SRC_URI[sha256sum] = "${JVM_CHECKSUM}"

JDK_VERSION = "11"
libdir_jdk = "${libdir}/jvm/openjdk-${JDK_VERSION}-jdk"

# Prevent the packaging task from stripping out
# debugging symbols, since there are none.
INSANE_SKIP:${PN} = "ldflags"
INHIBIT_PACKAGE_STRIP = "1"
INHIBIT_SYSROOT_STRIP = "1"
INHIBIT_PACKAGE_DEBUG_SPLIT = "1"

# Package unversioned libraries
SOLIBS = ".so"
FILES_SOLIBSDEV = ""

# Ignore QA Issue: non -dev/-dbg/nativesdk- package
INSANE_SKIP:${PN}:append = " dev-so"

# Ignore QA Issue: multiple shlibs to libjvm.so
do_package_qa[noexec] = "1"
EXCLUDE_FROM_SHLIBS = "1"

do_configure[noexec] = "1"
do_compile[noexec] = "1"
do_install() {
  install -d ${D}${libdir_jdk}
  cp -R --no-dereference --preserve=mode,links -v ${S}/* ${D}${libdir_jdk}
}

PROVIDES = "openjdk-${JDK_VERSION}-jdk"
FILES:${PN} = "${libdir_jdk}"
BBCLASSEXTEND += " native"
