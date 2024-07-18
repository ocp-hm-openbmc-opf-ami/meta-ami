FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"
SRC_URI += " \
	   file://dcmi_cap.json \
           file://dev_id.json \
           "
FILES:${PN} += " \
               ${sysconfdir}/ipmi \
               ${sysconfdir}/ipmi/channel_access.json \
               "

do_install:append() {
  install -m 0666 -d ${D}${sysconfdir}/ipmi
  cp ${D}${datadir}/ipmi-providers/channel_config.json ${D}${sysconfdir}/ipmi/channel_config.json
  ln -sf ${@oe.path.relative('${datadir}/ipmi-providers', '${sysconfdir}/ipmi/channel_config.json')} ${D}${datadir}/ipmi-providers/channel_config.json
}
