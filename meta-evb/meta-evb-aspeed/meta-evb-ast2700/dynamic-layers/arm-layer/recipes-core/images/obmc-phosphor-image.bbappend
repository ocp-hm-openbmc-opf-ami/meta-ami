IMAGE_INSTALL:append = " \
    ${@bb.utils.contains('MACHINE_FEATURES', 'ast-optee-os', 'packagegroup-optee-apps', '', d)} \
    "
