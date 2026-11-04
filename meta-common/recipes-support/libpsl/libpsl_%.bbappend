# Backport of OE-core 35014b128c "libpsl: use libidn2 instead of ICU".
# The default ICU backend pulls libicudata (~31.8MB, ~9.3MiB in squashfs-xz) into the image
# via curl -> libpsl, overflowing the fit-image-a partition on 64MB flash.
PACKAGECONFIG = "idn2"
