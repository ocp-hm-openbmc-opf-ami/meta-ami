FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRCREV ="04d12152001437186e7e0e907973d66311466a89"

SRC_URI += " \
  file://0001-Support-SPDM-1.1-functions.patch \
  file://0002-Migrate-to-libspdm-3.1.1.patch \
  file://sample_keys.tgz;subdir=./git \
"

include ${@bb.utils.contains('EXTRA_IMAGE_FEATURES', 'use-lfmctp', 'spdmapplib_lfmctp.inc', '', d)}

FILES:${PN} += " \
  ${datadir}/spdmd \ 
  ${datadir}/spdmd/sample_keys/rsa3072 \
  ${datadir}/spdmd/sample_keys/rsa3072/bundle_requester.certchain.der \
  ${datadir}/spdmd/sample_keys/rsa3072/end_requester.key \
"


