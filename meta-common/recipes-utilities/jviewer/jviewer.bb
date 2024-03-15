SUMMARY = "JViewer for AMI Onetree"
HOMEPAGE = "https://www.ami.com/megarac/#onetree"
LICENSE = "Proprietary"
LIC_FILES_CHKSUM = "file://${AMIBASE}/COPYING.AMI;md5=33abf79b43490ccebfe76ef9882fd8de"

# Need x86_64 version of JDK binaries for compilation
DEPENDS = "openjdk-11-jdk-native"

ALLOW_EMPTY:${PN} = "1"

SRC_URI = "git://git.ami.com/core/ami-bmc/one-tree/core/jviewer.git;protocol=https;branch=main"

PV = "1.0+git${SRCPV}"
SRCREV = "8e48c9181f8ec83609d120986a021d0b4654c6fe"

S = "${WORKDIR}/git"
JDK_DIR = "${RECIPE_SYSROOT_NATIVE}/usr/lib/jvm/openjdk-11-jdk/bin"

do_configure[noexec] = "1"
do_compile() {
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

  if [ -f ${JAVASIGNING_DIR}/JViewerKey ]; then
    echo ">> Signing JAR file......"

    # Hide displaying sensitive information in log
    {
      ${JDK_DIR}/jarsigner -keystore ${JAVASIGNING_DIR}/JViewerKey -storepass $(grep storepass ${JAVASIGNING_DIR}/KeyCredentials | cut -d':' -f2) JViewer.jar $(grep aliasname ${JAVASIGNING_DIR}/KeyCredentials | cut -d':' -f2)
    } &> /dev/null

    echo ">> Verifying JAR file signature"
    ${JDK_DIR}/jarsigner -verify -verbose -certs JViewer.jar | grep "s = signature was verified"

  else
    echo "Info: JAVASIGNING_DIR not found in local.conf. JAR file will not be signed!!!"
  fi

}

do_install() {
  install -d ${DEPLOY_DIR_IMAGE}/utilities/JViewer_StandAloneApp
  cp bin/JViewer.jar ${DEPLOY_DIR_IMAGE}/utilities/JViewer_StandAloneApp/
}
