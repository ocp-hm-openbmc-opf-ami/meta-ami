FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

do_install:append() {
    # the default dummy data provided for this file causes breakage in
    # Get SDR commands.  Clearing out the provided entity-map entirely
    # avoids the issue.
    echo "[]" > ${D}${datadir}/ipmi-providers/entity-map.json
}