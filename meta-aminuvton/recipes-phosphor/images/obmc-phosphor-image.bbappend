OBMC_IMAGE_EXTRA_INSTALL:append:devkit-npcm845 = " \
    entity-manager \
    dbus-sensors \
    phosphor-pid-control \
    x86-power-control \
"

# for s997
IMAGE_INSTALL:append:s997 = " numctl"
