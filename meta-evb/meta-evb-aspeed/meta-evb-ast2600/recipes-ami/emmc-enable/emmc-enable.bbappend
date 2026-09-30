FILESEXTRAPATHS:append := ":${THISDIR}/files"

SRC_URI:append= "file://sd_partition_info_rwfs.json \
"


# Custom task to convert JSON to conf file
python do_convert_json_to_conf() {
    import json
    import os

    if bb.utils.contains('IMAGE_FEATURES', 'onetree-dual-image-common-conf', True, False, d):
        json_name = 'sd_partition_info_rwfs.json'
    else:
        json_name = 'sd_partition_info.json'

    json_file = os.path.join(d.getVar('UNPACKDIR'), json_name)
    conf_file = os.path.join(d.getVar('UNPACKDIR'), 'sd_partition_info.conf')

    def convert_json_to_conf(json_data):
        device = json_data["sdcard"]["DEVICE_NAME"]
        num_parts = json_data["sdcard"]["PARTITION_COUNT"]
        clean_parts = " ".join(json_data["sdcard"]["CLEAN_PARTS"])
        
        part_sizes_mb = " ".join([partition["size_mb"] for partition in json_data["partitions"]])
        part_names = " ".join([partition["name"] for partition in json_data["partitions"]])
        part_fs_types = " ".join([partition["fs_type"] for partition in json_data["partitions"]])
        mount_paths = " ".join([partition["mnt_path"] for partition in json_data["partitions"]])
        
        conf_content = f"""DEVICE={device}
NUM_PARTS={num_parts}
PART_SIZES_MB="{part_sizes_mb}"
PART_NAMES="{part_names}"
PART_FS_TYPES="{part_fs_types}"
MOUNT_PATHS="{mount_paths}"
CLEAN_PARTS="{clean_parts}"
"""
        return conf_content

    with open(json_file, 'r') as f:
        json_data = json.load(f)

    conf_content = convert_json_to_conf(json_data)

    with open(conf_file, 'w') as f:
        f.write(conf_content)

    bb.note("The JSON data has been successfully converted to partition.conf format.")
}

# Add the custom task to the recipe
addtask do_convert_json_to_conf after do_compile before do_install

do_install:append() {
    if ${@bb.utils.contains('IMAGE_FEATURES', 'onetree-dual-image-common-conf', 'true', 'false', d)}; then
        install -d ${D}${sysconfdir}
        install -m 0644 ${UNPACKDIR}/sd_partition_info.conf ${D}${sysconfdir}/
    fi    
}


