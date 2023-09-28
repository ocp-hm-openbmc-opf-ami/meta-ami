FILESEXTRAPATHS:append := "${THISDIR}/${PN}:"

#SRC_URI_EGS:append = " file://0001-Added-VmediaService-PmtService-to-Service-Config-Manager.patch"
#SRC_URI:append = "${@bb.utils.contains('BBFILE_COLLECTIONS', 'egs', "${@bb.utils.contains('BBFILE_COLLECTIONS', 'restricted','', SRC_URI_EGS, d)}", '', d)}"
#SRC_URI_EGS_RES:append = " file://0001-Added-Virtualmedia-service-to-service-Config-Manager.patch"
#SRC_URI:append = "${@bb.utils.contains('BBFILE_COLLECTIONS', 'egs', "${@bb.utils.contains('BBFILE_COLLECTIONS', 'restricted', SRC_URI_EGS_RES, '',d)}", '', d)}"

