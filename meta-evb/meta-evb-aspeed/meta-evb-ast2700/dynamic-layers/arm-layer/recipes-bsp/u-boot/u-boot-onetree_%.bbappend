do_compile[depends] += " \
    ${@bb.utils.contains('MACHINE_FEATURES', 'ast-optee-os', 'optee-os:do_deploy', '', d)} \
    ${@bb.utils.contains('MACHINE_FEATURES', 'ast-arm-trusted-firmware-a', 'trusted-firmware-a:do_deploy', '', d)} \
    "
