FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

PACKAGECONFIG:remove = " use-json use-lamp-test"

PACKAGECONFIG:append = " use-yaml"

