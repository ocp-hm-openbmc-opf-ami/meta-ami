FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

#removing old SRCREV , latest SRCREV added in openbmc-meta-intel


do_install:append(){
  install -d ${D}${includedir}/phosphor-ipmi-host
  install -m 0644 -D ${S}/sensorhandler.hpp ${D}${includedir}/phosphor-ipmi-host
  install -m 0644 -D ${S}/selutility.hpp ${D}${includedir}/phosphor-ipmi-host
  

}

