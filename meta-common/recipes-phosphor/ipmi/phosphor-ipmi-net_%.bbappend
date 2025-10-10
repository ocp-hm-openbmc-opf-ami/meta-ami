inherit useradd

USERADD_PACKAGES = "${PN}"
# add a group called ipmi
GROUPADD_PARAM:${PN} = "ipmi "

FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

# Enable downstream autobump to fix sync build, can be removed later
# The URI is required for the autobump script but keep it commented
# to not override the upstream value
# SRC_URI += "git://github.com/openbmc/phosphor-net-ipmid;branch=master;protocol=https"
SRCREV = "36e3c539df647d579f00f1cba6b482692a4ed634"

SRC_URI += " file://10-nice-rules.conf \
             file://0012-rakp12-Add-username-to-SessionInfo-interface.patch \
           "

#file://0013-Fix-for-SOL-deactivate-IPMI-command.patch

do_install:append() {
    mkdir -p ${D}${sysconfdir}/systemd/system/phosphor-ipmi-net@.service.d/
    install -m 0644 ${WORKDIR}/10-nice-rules.conf ${D}${sysconfdir}/systemd/system/phosphor-ipmi-net@.service.d/
}
