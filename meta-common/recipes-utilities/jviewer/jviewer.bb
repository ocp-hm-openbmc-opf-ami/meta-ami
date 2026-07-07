SUMMARY = "JViewer for AMI Onetree"
HOMEPAGE = "https://www.ami.com/megarac/#onetree"
LICENSE = "Proprietary"
LIC_FILES_CHKSUM = "file://${AMIBASE}/COPYING.AMI;md5=65a69a674f34a9f30737c9f0abd4fc5c"

# Compile using N-1 LTS version to support both N and N-1 versions
JDK_VERSION = "11"
# Need x86_64 version of JDK binaries for compilation
DEPENDS = "openjdk-${JDK_VERSION}-jdk-native curl-native"

ALLOW_EMPTY:${PN} = "1"

# Pre-built JAR location in recipe directory
PREBUILT_JAR = "${THISDIR}/JViewer.jar"

SRC_URI = "git://git.ami.com/core/ami-bmc/one-tree/core/jviewer.git;protocol=https;branch=main"

PV = "1.0+git${SRCPV}"
SRCREV = "4974df37821c1a08dfeef343d2ca5120e8f10dc7"

S = "${WORKDIR}/git"
JDK_DIR = "${RECIPE_SYSROOT_NATIVE}/usr/lib/jvm/openjdk-${JDK_VERSION}-jdk/bin"

do_configure[noexec] = "1"

do_compile() {
    
  # Check if pre-built JAR exists in recipe directory
  if [ -f "${PREBUILT_JAR}" ]; then
    bbwarn "Using pre-built JAR. Skipping compilation."
    cd ${S}
    mkdir -p bin
    cp "${PREBUILT_JAR}" bin/JViewer.jar
    return 0
  fi

  cd ${S}
  echo ">> Compiling using........."
  ${JDK_DIR}/javac -version

  rm -rf bin

  mkdir -p bin
  ${JDK_DIR}/javac \
  --module-path deps \
  -d bin \
  src/module-info.java \
  src/com/ami/httpclient/*.java \
  src/com/ami/iusb/*.java \
  src/com/ami/iusb/protocol/*.java \
  src/com/ami/kvm/imageredir/*.java \
  src/com/ami/kvm/imageredir/cd/*.java \
  src/com/ami/kvm/isocaching/*.java \
  src/com/ami/kvm/jviewer/*.java \
  src/com/ami/kvm/jviewer/avistream/*.java \
  src/com/ami/kvm/jviewer/common/*.java \
  src/com/ami/kvm/jviewer/common/folderredir/*.java \
  src/com/ami/kvm/jviewer/common/oem/*.java \
  src/com/ami/kvm/jviewer/communication/*.java \
  src/com/ami/kvm/jviewer/folderredir/*.java \
  src/com/ami/kvm/jviewer/folderredir/core/*.java \
  src/com/ami/kvm/jviewer/folderredir/gui/*.java \
  src/com/ami/kvm/jviewer/folderredir/lang/*.java \
  src/com/ami/kvm/jviewer/gui/*.java \
  src/com/ami/kvm/jviewer/hid/*.java \
  src/com/ami/kvm/jviewer/jvvideo/*.java \
  src/com/ami/kvm/jviewer/kvmpkts/*.java \
  src/com/ami/kvm/jviewer/lang/*.java \
  src/com/ami/kvm/jviewer/oem/*.java \
  src/com/ami/kvm/jviewer/oem/gui/*.java \
  src/com/ami/kvm/jviewer/oem/lang/*.java \
  src/com/ami/kvm/jviewer/soc/*.java \
  src/com/ami/kvm/jviewer/soc/lang/*.java \
  src/com/ami/kvm/jviewer/soc/reader/*.java \
  src/com/ami/kvm/jviewer/soc/video/*.java \
  src/com/ami/kvm/jviewer/videorecord/*.java \
  src/com/ami/nbd/*.java \
  src/com/ami/rfb/*.java \
  src/com/ami/vmedia/*.java \
  src/com/ami/vmedia/gui/*.java

  echo ">> Copying resources......."
  cp -r src/com/ami/kvm/jviewer/res bin/com/ami/kvm/jviewer/
  cp -r src/com/ami/kvm/jviewer/lib bin/com/ami/kvm/jviewer/
 
  echo ">> Generating JAR file....."
  cd bin
  ${JDK_DIR}/jar --create \
  --file JViewer.jar \
  --main-class com.ami.kvm.jviewer.JViewer \
  *

}

do_install() {
  install -d ${DEPLOY_DIR_IMAGE}/utilities/JViewer_StandAloneApp
  cp bin/JViewer.jar ${DEPLOY_DIR_IMAGE}/utilities/JViewer_StandAloneApp/
}
