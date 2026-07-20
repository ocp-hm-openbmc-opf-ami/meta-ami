FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"
SRC_URI += " \
           file://cipher_list.json \
           file://dev_id.json \
           "
SRCREV = "e7ef94d350cd156c54a5789ce7d53eb1a55f7da9"

SRC_URI_NM:append = "file://dcmi_cap.json"
SRC_URI:append = "${@bb.utils.contains('EXTRA_IMAGE_FEATURES', 'onetree-intelsipack', SRC_URI_NM, '', d)}"
FILES:${PN} += " \
               ${sysconfdir}/ipmi \
               ${sysconfdir}/ipmi/channel_access.json \
               "

do_install:append() {
  install -m 0666 -d ${D}${sysconfdir}/ipmi
  cp ${D}${datadir}/ipmi-providers/channel_config.json ${D}${sysconfdir}/ipmi/channel_config.json
  ln -sf ${@oe.path.relative('${datadir}/ipmi-providers', '${sysconfdir}/ipmi/channel_config.json')} ${D}${datadir}/ipmi-providers/channel_config.json
}
