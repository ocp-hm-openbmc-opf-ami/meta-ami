# Ports the old DevKit layer.conf IMAGE_INSTALL list; ipmitool, phosphor-sel-logger,
# default-fru and dbus-sensors already come from the evb-ast2600 image append.
OBMC_IMAGE_EXTRA_INSTALL:append = " \
    pwmtachtool \
    adcapp \
    entity-manager \
    bmcweb \
    phosphor-ipmi-kcs \
    phosphor-ipmi-net \
    phosphor-ipmi-ipmb \
    phosphor-user-manager \
    phosphor-network \
    obmc-console \
    obmc-ikvm \
    jsnbd \
"