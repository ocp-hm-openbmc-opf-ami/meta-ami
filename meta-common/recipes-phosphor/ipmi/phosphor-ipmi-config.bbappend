FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"
SRC_URI += " \
	   file://dcmi_cap.json \
           file://dev_id.json \
           "
SRCREV = "e7ef94d350cd156c54a5789ce7d53eb1a55f7da9"

FILES:${PN} += " \
               ${sysconfdir}/ipmi \
               ${sysconfdir}/ipmi/channel_access.json \
               "

do_install:append() {
  install -m 0666 -d ${D}${sysconfdir}/ipmi
  cp ${D}${datadir}/ipmi-providers/channel_config.json ${D}${sysconfdir}/ipmi/channel_config.json
  ln -sf ${@oe.path.relative('${datadir}/ipmi-providers', '${sysconfdir}/ipmi/channel_config.json')} ${D}${datadir}/ipmi-providers/channel_config.json
}
