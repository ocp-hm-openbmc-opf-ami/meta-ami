FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

EXTRA_OEMESON:append = " \
    -Dredfish-provisioning-feature=enabled \
    ${@bb.utils.contains('BBFILE_COLLECTIONS', 'evb-ast2600', ' -Dupdate_timeout=30','', d)} \
"

PACKAGECONFIG:append = " \
    redfish-dbus-log \
    redfish-dump-log \
"

# add "redfish-hostiface" group
GROUPADD_PARAM:${PN}:append = ";redfish-hostiface"

SRC_URI = "git://git@github.com/ocp-hm-openbmc-opf-ami/bmcweb;protocol=https;branch=master;name=override;"
SRCREV_FORMAT = "override"
SRCREV_override = "b76407e4d11621c47c86598d74e871071b9ccc26"

#EXTRA_OEMESON += "${@bb.utils.contains('IMAGE_FSTYPES', 'intel-pfr', '-Dintel-pfr=enabled',' ', d)}"
#EXTRA_OEMESON += "${@bb.utils.contains('BBFILE_COLLECTIONS', 'meta-mgx','-Dredfish-intel-feature=enabled','', d)}"
#EXTRA_OEMESON += "${@bb.utils.contains('BBFILE_COLLECTIONS', 'mtmitchell-layer', '-Dredfish-intel-feature=enabled', '', d)}"

DEPENDS += "phosphor-snmp"

# To get run time features during build time
python () {
    feats = d.getVar('EXTRA_IMAGE_FEATURES')
    meson_arg = " -Dextra_image_features='%s'" % feats
    d.setVar('EXTRA_OEMESON', d.getVar('EXTRA_OEMESON') + meson_arg)
    
    platform = d.getVar('BBFILE_COLLECTIONS')
    meson_arg = " -Dbbfile_collections='%s'" % platform
    d.setVar('EXTRA_OEMESON', d.getVar('EXTRA_OEMESON') + meson_arg)
    
    fstypes = d.getVar('IMAGE_FSTYPES')
    meson_arg = " -Dimage_fstypes='%s'" % fstypes
    d.setVar('EXTRA_OEMESON', d.getVar('EXTRA_OEMESON') + meson_arg)
}

# To update configuration using ODS tool
python () {
    for k in d.keys():
        if k.startswith("BMCWEB_"):
            v = d.getVar(k)
            if v is None:
                continue
            # Normalize boolean values
            if v.lower() in ["true", "false"]:
                opt = v.lower()
            else:
                opt = v

            suffix = k[len("BMCWEB_"):]
            d.appendVar("EXTRA_OEMESON", f" -D{suffix}={opt}")
}

# Remove http-zstd from PACKAGECONFIG
PACKAGECONFIG:remove:pn-bmcweb = "http-zstd"
EXTRA_OEMESON:remove:pn-bmcweb = "-Dhttp-zstd=enabled"
EXTRA_OEMESON:remove:pn-bmcweb = "-Dhttp-zstd=disabled"

