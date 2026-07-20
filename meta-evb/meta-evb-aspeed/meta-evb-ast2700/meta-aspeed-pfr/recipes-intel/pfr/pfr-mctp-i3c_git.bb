SUMMARY = "MCTP Daemon for PFR 4.0"
DESCRIPTION = "MCTP Daemon for communicating with AST1060 via i3c"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/files/common-licenses/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

inherit pkgconfig meson

SRC_URI = " file://main.c;subdir=${BP} \
            file://meson.build;subdir=${BP} \
            file://pfr-mctp-i3c.service;subdir=${BP} \
            file://mctp-i3c-starter.sh;subdir=${BP} \
          "

inherit obmc-phosphor-systemd
SYSTEMD_SERVICE:${PN} = "pfr-mctp-i3c.service"

