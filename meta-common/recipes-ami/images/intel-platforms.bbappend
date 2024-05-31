inherit obmc-phosphor-signining

ROOTFS_POSTPROCESS_COMMAND:remove = "set_user_groupdo_populate_static_lic;"
ROOTFS_POSTPROCESS_COMMAND:append = " set_user_group do_populate_static_lic "

