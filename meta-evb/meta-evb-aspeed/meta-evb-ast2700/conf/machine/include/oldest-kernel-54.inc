# glibc
# --enable-kernel=version
# This option is currently only useful on GNU/Linux systems.
# The version parameter should have the form X.Y.Z and describes the smallest
# version of the Linux kernel the generated library is expected to support.
# The higher the version number is, the less compatibility code is added,
# and the faster the code gets.

# Yocto set the oldest kernel version to 5.15 in bitbake.conf
# To support kernel 5.4 and fix compatible issue, set oldest kernel version to
# 5.4 in ASPEED SDK.
OLDEST_KERNEL = "5.4"

PREFERRED_PROVIDER_virtual/bootloader = "u-boot-onetree"
PREFERRED_PROVIDER_u-boot = "u-boot-onetree"
PREFERRED_PROVIDER_u-boot-fw-utils = "u-boot-fw-utils-onetree"

PREFERRED_VERSION_u-boot-onetree = "v2023.10+%"
PREFERRED_VERSION_u-boot-fw-utils-onetree = "v2023.10+%"
