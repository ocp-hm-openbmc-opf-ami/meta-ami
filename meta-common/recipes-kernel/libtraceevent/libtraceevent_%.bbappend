# meta-phosphor enables -Db_lto=true for all meson target recipes. With LTO,
# GCC streams the build directory (WORKDIR) into the LTO bytecode of the
# objects archived in libtraceevent.a, ignoring -ffile-prefix-map
# (https://gcc.gnu.org/bugzilla/show_bug.cgi?id=109805). This trips the
# [buildpaths] QA check on libtraceevent-staticdev, so disable LTO here.
EXTRA_OEMESON:append = " -Db_lto=false"
