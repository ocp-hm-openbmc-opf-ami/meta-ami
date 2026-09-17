# AMI packages for tiogapass.
IMAGE_INSTALL:append = " \
    pwmtachtool \
    adcapp \
    logger-systemd \
    ipmitool \
    phosphor-ipmi-kcs \
    bmcweb \
    entity-manager \
    dbus-sensors \
    phosphor-network \
    phosphor-sel-logger \
    obmc-console \
    obmc-ikvm \
    rng-tools \
    "

# Use dropbear for tiogapass.
IMAGE_FEATURES:remove = "ssh-server-openssh"
IMAGE_FEATURES:append = " ssh-server-dropbear"

# Trim non-essential packages for the 32MB image.
IMAGE_INSTALL:remove = " \
    strace \
    tcpdump \
    tmux \
    dbus-top \
    usbutils \
    systemd-analyze \
    jq \
    wget \
    "

# Remove optional image features not used on tiogapass.
EXTRA_IMAGE_FEATURES:remove = " \
    onetree-snmp \
    onetree-lldpd \
    onetree-network-system-firewall-support \
    onetree-network-disable-ping-support \
    onetree-telemetry \
    onetree-rbc-mgr \
    onetree-2fa \
    onetree-slpd \
    onetree-smtp \
    onetree-pdk \
    onetree-network-nsupdate-support \
    onetree-network-tsig-support \
    onetree-network-avahi-support \
    onetree-radius-client \
    "

# Skip locale payloads.
IMAGE_LINGUAS = ""

# Remove bundled Redfish schemas.
remove_redfish_schemas() {
    rm -rf ${IMAGE_ROOTFS}/usr/share/www/redfish
}

# Keep only UTC zoneinfo data.
trim_zoneinfo() {
    find ${IMAGE_ROOTFS}/usr/share/zoneinfo/ -mindepth 1 -maxdepth 1 \
        ! -name "Etc" ! -name "UTC" ! -name "posixrules" ! -name "tzdata.zi" \
        -exec rm -rf {} +
}

# Keep only tiogapass entity-manager data.
prune_entity_manager_configs() {
    local cfgdir="${IMAGE_ROOTFS}/usr/share/entity-manager/configurations"
    for d in "${cfgdir}"/*/; do
        case "${d}" in
            */meta/) ;;
            *) rm -rf "${d}" ;;
        esac
    done
    find "${cfgdir}/meta" -name "*.json" ! -name "fbtp.json" -delete
    find "${cfgdir}/meta" -mindepth 1 -maxdepth 1 -type d -exec rm -rf {} +
}

# Remove unused OpenSSL provider modules.
remove_ossl_optional_modules() {
    rm -f ${IMAGE_ROOTFS}/usr/lib/ossl-modules/fips.so \
          ${IMAGE_ROOTFS}/usr/lib/ossl-modules/legacy.so
}

# Remove the opkg database.
remove_opkg_db() {
    rm -rf ${IMAGE_ROOTFS}/usr/lib/opkg
}

# Remove the Intel OEM IPMI provider.
remove_intel_ipmid_provider() {
    find ${IMAGE_ROOTFS}/usr/lib/ipmid-providers -maxdepth 1 \
        -name "libzinteloemcmds.so*" -delete
}

# Remove cracklib dictionaries.
remove_cracklib_dict() {
    rm -f ${IMAGE_ROOTFS}/usr/share/cracklib/cracklib-small \
          ${IMAGE_ROOTFS}/usr/share/cracklib/pw_dict.pwd \
          ${IMAGE_ROOTFS}/usr/share/cracklib/pw_dict.pwi \
          ${IMAGE_ROOTFS}/usr/share/cracklib/pw_dict.hwm
}

# Remove unused BIND DNS tools and libraries.
remove_bind_dns_tools() {
    rm -f \
        ${IMAGE_ROOTFS}/usr/bin/nsupdate \
        ${IMAGE_ROOTFS}/usr/bin/dig \
        ${IMAGE_ROOTFS}/usr/bin/host \
        ${IMAGE_ROOTFS}/usr/bin/nslookup.bind \
        ${IMAGE_ROOTFS}/usr/bin/mdig
    find ${IMAGE_ROOTFS}/usr/lib -maxdepth 1 \( \
        -name "libdns-*.so"    -o \
        -name "libisc-*.so"    -o \
        -name "libisccc-*.so"  -o \
        -name "libisccfg-*.so" -o \
        -name "libns-*.so"     \
    \) -delete
}

ROOTFS_POSTPROCESS_COMMAND:append = " \
    remove_redfish_schemas; \
    trim_zoneinfo; \
    prune_entity_manager_configs; \
    remove_ossl_optional_modules; \
    remove_opkg_db; \
    remove_intel_ipmid_provider; \
    remove_cracklib_dict; \
    remove_bind_dns_tools; \
    "
