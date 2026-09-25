# Ensure native test helpers link with pthread
CFLAGS:append:pn-libgcrypt-native  = " -pthread"
LDFLAGS:append:pn-libgcrypt-native = " -pthread"

# (Optional) native speed/stability tweak; safe for native build
EXTRA_OECONF:append:pn-libgcrypt-native = " --disable-asm --disable-doc"
