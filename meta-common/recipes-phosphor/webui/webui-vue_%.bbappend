# Enable downstream autobump
# # The URI is required for the autobump script but keep it commented
# to not override the upstream value
# SRC_URI = "git://github.com/openbmc/webui-vue.git;branch=master;protocol=https"
SRCREV = "f763cd2e39ffce9b10191402243e8704794f08ff"
FILESEXTRAPATHS:append := "${THISDIR}/${PN}:"
SRC_URI += " \
    file://login-company-logo.svg \
    file://logo-header.svg \
    file://0001-Session-timeout-feature-in-webui.patch \
    file://0002-NTP-date-and-time-syncing-issue-fixed.patch \
    file://0003-User-Management-Enabled-Disabled-Custom-error-change.patch \
    file://0004-SSL-Certificate-certificate-creation-changes.patch \
    file://0005-Network-Configuration-Changes.patch \
    file://0006-Sensor-state-threshold-values-are-not-getting-update.patch \
    file://0007-virtual-media-support-multiple-media-types.patch \
    file://0008-Support-for-Multiple-Service-configurations-like-KVM.patch \
    file://0009-Restrict-able-to-disable-change-privilege-from-root.patch \
    file://0010-Implementing-Factory-Default-page-in-webui.patch \
    file://0011-Fix-for-able-to-access-KVM-windows-even-after-loggin.patch \
    file://0012-Operations-section-and-Server-status-is-not-getting-.patch \
    file://0013-VLAN-feature-support-in-WEBUI.patch \
    file://0014-password-policies-in-webui.patch \
    file://0015-invalid-password-shows-wrong-error-response.patch \
    file://0016-virtual-media-file-type-validation-changes.patch \
    file://0017-IPV6-Configuration-support-implementation.patch \
    file://0018-Ldap-feature-enabled-in-webui.patch \
    file://0019-Web-UI-not-showing-active-sessions.patch \
    file://0020-Time-zone-configuration-support-Implementation.patch \
    file://0021-KVM-master-session-check-from-WEBUI.patch \
    file://0022-description-for-complexity-and-password-history.patch \
    file://0023-WEB-UI-Customization.patch \
    file://favicon.ico \
    file://0024-Time-zone-configuration-not-working-as-expected.patch \
    file://0025-SSL-Page-certificates-validity-time-mismatch.patch \
    file://0026-WEBUI-cosmetic-design-changes.patch \
    file://0027-Unable-to-edit-the-static-ipv6-address.patch \
    file://0028-Added-PEF-Feature-Support-in-WEBUI.patch \
    file://0029-BMC-dump-feature-from-webui.patch \
    file://0030-Added-Physical-Indicator-LED-status.patch \
    file://0031-Virtual-media-Load-image-not-able-to-configure.patch \
    file://0032-Removed-the-System-Dump-option-in-dropdown-list.patch \
    "
do_compile:prepend() {
  cp -vf ${S}/.env.intel ${S}/.env
  cp -vf ${WORKDIR}/login-company-logo.svg ${S}/src/assets/images
  cp -vf ${WORKDIR}/logo-header.svg ${S}/src/assets/images
  cp -vf ${WORKDIR}/favicon.ico ${S}/public
}
