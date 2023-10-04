FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRCREV ="04d12152001437186e7e0e907973d66311466a89"

SRC_URI += " \
  file://Support-SPDM-1.1-functions.patch \
  file://sample_keys.tgz;subdir=./git \
"

FILES:${PN} += " \
  ${datadir}/spdmd \ 
  ${datadir}/spdmd/sample_keys/rsa3072 \
  ${datadir}/spdmd/sample_keys/rsa3072/bundle_requester.certchain.der \
  ${datadir}/spdmd/sample_keys/rsa3072/end_requester.key \
"


