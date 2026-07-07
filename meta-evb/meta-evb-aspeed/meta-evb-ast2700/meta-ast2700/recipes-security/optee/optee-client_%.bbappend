# Fix GID conflicts: teepriv and teesuppl were getting GIDs that conflict with systemd groups
# systemd-resolve is defined with GID 207 in meta-core/files/group
# systemd-timesync has GID 204
# Assign explicit GIDs to avoid conflicts:
#   - teepriv: GID 210 (was auto-assigned 207)
#   - teesuppl: GID 211 (was auto-assigned 207 in second build)
# Note: tee group uses auto-assignment and should get 208 which is available
GROUPADD_PARAM:${PN} = "--system ${TEE_GROUP_NAME}; --system --gid 210 teepriv; --system --gid 211 teesuppl"
