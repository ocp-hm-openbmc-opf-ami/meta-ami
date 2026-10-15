# Extends the search path the OpenEmbedded build system uses when looking for files and patches as it processes recipes and append files
FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

# The list of source files — local or remote
SRC_URI_EXT:append= " \
        file://common \
"
SRC_URI:append = "${@bb.utils.contains_any('IMAGE_FEATURES', 'onetree-msccraid onetree-nvme onetree-nvmebasic onetree-brcmraid onetree-brcmraid8 onetree-rtp', SRC_URI_EXT, '', d)}"

do_configure:prepend() {
  if ${@bb.utils.contains_any('IMAGE_FEATURES',' onetree-msccraid onetree-nvme onetree-nvmebasic onetree-brcmraid onetree-brcmraid8 onetree-rtp','true','false',d)}; then
    if [ ! -d "${S}/ext" ]; then
        # Create the folder if it doesn't exist
       mkdir -p "${S}/ext"
    fi
    cp -rin ${UNPACKDIR}/common/* ${S}/ext/
  fi
}

# The schema folder path
SCHEMA_DIR = "${datadir}/www/redfish/v1"

do_install:append() {
	if [ -d "${S}/ext/schema/oem/ami/" ]; then
	cp -r ${S}/ext/schema/oem/ami/csdl/* ${D}${SCHEMA_DIR}/schema/
	cp -r ${S}/ext/schema/oem/ami/json_schema/* ${D}${SCHEMA_DIR}/JsonSchemas/
	fi
}

