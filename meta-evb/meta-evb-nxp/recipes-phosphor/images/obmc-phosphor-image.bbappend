SYSTEMD_PACKAGES = "${PN}"
SYSTEMD_SERVICE:${PN} = "phosphor-mboxd.service phosphor-ipmi-kcs.service phosphor-lpcd.service"
SYSTEMD_MASK:${PN} = "phosphor-mboxd.service phosphor-ipmi-kcs.service phosphor-lpcd.service"


OBMC_IMAGE_EXTRA_INSTALL:append:nxp = " mboxd liberation-fonts uart-render-controller nxp-hostctrl host-reset webui-vue "
