SUMMARY = "Multi-Host configuration service"
DESCRIPTION = "Script for setting Multi-Host configuration"

LICENSE = "CLOSED"

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

inherit obmc-phosphor-systemd

RDEPENDS:${PN} += "libsystemd bash"
DEPENDS += " systemd"

S="${WORKDIR}/git"

SRC_URI += " \
        file://multi-host-config \
        "

# Default mode: 0 = 2P (single host), 1 = 2x1P (multi-host)
# Override this in machine.conf or local.conf
MULTI_HOST_DEFAULT_MODE ?= "0"

do_install:append() {
  install -d ${D}/${sbindir}
  install -m 0755 ${WORKDIR}/multi-host-config ${D}/${sbindir}/multi-host-config

  # Create config directories
  install -d ${D}/etc/multi-host-config
  install -d ${D}/etc/multi-host-config/hosts.d
  install -d ${D}/var/lib/multi-host-config

  # Create hosts.d files based on MULTI_HOST_DEFAULT_MODE
  if [ "${MULTI_HOST_DEFAULT_MODE}" = "1" ]; then
      # Mode 1: 2x1P (multi-host)
      touch ${D}/etc/multi-host-config/hosts.d/host1.conf
      touch ${D}/etc/multi-host-config/hosts.d/host2.conf
      echo "1" > ${D}/var/lib/multi-host-config/current-mode
  else
      # Mode 0: 2P (single host) - default
      touch ${D}/etc/multi-host-config/hosts.d/host0.conf
      echo "0" > ${D}/var/lib/multi-host-config/current-mode
  fi
}

FILES:${PN} += " \
    /etc/multi-host-config \
    /etc/multi-host-config/hosts.d \
    /etc/multi-host-config/hosts.d/* \
    /var/lib/multi-host-config \
    /var/lib/multi-host-config/* \
"

SYSTEMD_PACKAGES = "${PN}"
SYSTEMD_SERVICE:${PN} += "multi-host-config.service"

