# LTO leaves GIMPLE bytecode with unmapped build paths inside libtraceevent.a,
# which trips the buildpaths QA check on libtraceevent-staticdev.
EXTRA_OEMESON:remove = "-Db_lto=true"
