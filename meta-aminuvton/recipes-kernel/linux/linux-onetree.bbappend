FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

# fdtoverlay/dtc for build-time device-tree overlay merge
DEPENDS:append = " dtc-native"

SRC_URI:append:devkit-npcm845 = " \
    file://0001-identify-ami-devkit-npcm845.patch;apply=no \
    file://devkit-npcm845.cfg \
"

# for s997 (set S997_ENABLE = "0" in the machine conf to build without s997 related changes)
SRC_URI:append:s997 = " file://s997.cfg"

SRC_URI:append:s997 = " file://dts-arbel-npcm845-s997/"

do_configure:append:devkit-npcm845() {
    patch --batch --forward --fuzz=0 -p1 -d ${S}/arch/arm64/boot/dts/nuvoton \
        < ${UNPACKDIR}/0001-identify-ami-devkit-npcm845.patch
}

# Merge standalone device-tree overlays into the board dtb at build time.
# The base dtb is built with DTC_FLAGS=-@ (see linux-onetree.bb) so it carries
# __symbols__, allowing fdtoverlay to resolve labels like &gpio0 / &i2c4.
# Every *.dtso under dts-arbel-npcm845-s997/ is compiled and applied in filename order.
do_compile:append (){
    dtb="${B}/arch/arm64/boot/dts/nuvoton/nuvoton-npcm845-evb.dtb"
    overlay_dir="${UNPACKDIR}/dts-arbel-npcm845-s997"

    [ -f "${dtb}" ] || return 0

    dtbos=""
    for src in ${overlay_dir}/*.dtso; do
        [ -e "${src}" ] || continue
        out="${B}/$(basename ${src} .dtso).dtbo"
        dtc -@ -I dts -O dtb -o "${out}" "${src}"
        dtbos="${dtbos} ${out}"
    done

    if [ -n "${dtbos}" ]; then
        fdtoverlay -i "${dtb}" -o "${dtb}.merged" ${dtbos}
        mv "${dtb}.merged" "${dtb}"
    fi
}
