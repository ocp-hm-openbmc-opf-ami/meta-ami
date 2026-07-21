# Enable downstream autobump
# The URI is required for the autobump script but keep it commented
# to not override the upstream value
# SRC_URI = "git://github.com/openbmc/webui-vue.git;branch=master;protocol=https"
# SRCREV = "f763cd2e39ffce9b10191402243e8704794f08ff"

# AMI own repository for webui-vue with main branch
SRC_URI = "git://git@github.com/ocp-hm-openbmc-opf-ami/webui-vue;protocol=https;branch=main"

# Use AUTOREV to get the latest revision from the repository
# SRCREV = "${AUTOREV}"
SRCREV_webui = "c757b32cc2940f19429af1903d3d0bda9f20c150"
SRCREV_webuilib = "2e641fcbb209e6b64c15ca18498afc857bbd3f16"
SRCREV_FORMAT = "webui_webuilib"

SRC_URI += " \
    file://login-company-logo.svg \
    file://logo-header.svg \
    git://github.com/ocp-hm-openbmc-opf-ami/webui-libraries.git;branch=main;protocol=https;destsuffix=webui-libs;name=webuilib \
    "
FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"
do_compile:prepend() {
    bbplain "****************************** Features Enabled in This Firmware Image ***********************************************"
    i=1
    for feature in ${EXTRA_IMAGE_FEATURES}; do
        bbplain "$i. $feature"
        i=$(expr "$i" + 1)
    done

    bbplain "*****************************************************************************"

    if [ ! -f ${S}/.env.intel ]; then
        bbwarn ".env.intel not found, creating from .env.ami..."
    fi

    cp -vf ${S}/.env.ami ${S}/.env.intel

    i=1
    for feature in ${EXTRA_IMAGE_FEATURES}; do
        ENV_VAR_NAME=$(echo "$feature" | tr '[:lower:]' '[:upper:]' | tr '-' '_')
        ENV_LINE="VUE_APP_${ENV_VAR_NAME}_ENABLED=\"true\""

        if [ $i -eq 1 ]; then
            echo "" >> ${S}/.env.intel
        fi

        if ! grep -q "^${ENV_LINE}$" ${S}/.env.intel; then
            echo "${ENV_LINE}" >> ${S}/.env.intel
            bbplain "$i. ${ENV_LINE}"
        else
            bbwarn "Skipped (Duplicate feature already exists): $i. ${ENV_LINE}"
        fi
        i=$(expr "$i" + 1)
    done

    ALL_VUE_APP_VARS=$(env | awk -F= '/^VUE_APP/ {print $1}')

    for var in $ALL_VUE_APP_VARS; do
        value="$(env | grep "^${var}=" | cut -d= -f2-)"

        if grep -q "^${var}=" ${S}/.env.intel; then
            # Replace existing line with new value (quoted)
            sed -i "s|^${var}=.*|${var}=\"${value}\"|" ${S}/.env.intel
        else
            # Append new variable
            echo "${var}=\"${value}\"" >> ${S}/.env.intel
        fi
    done

    bbwarn "Generated environment variables in .env file"

    cp -vf ${S}/.env.intel ${S}/.env
    while IFS= read -r line; do
        bbplain "$line"
    done < ${S}/.env.intel
}

# Disable network access - dependencies are provided via vendored node_modules
do_compile[network] = "0"

# Extract node_modules once at configure time.
# do_configure is sstate-cached: extraction is skipped on unchanged rebuilds,
# avoiding the performance cost of untarring 200-500 MB on every compile.
do_configure:append() {
    if [ ! -f "${UNPACKDIR}/webui-libs/node_modules.tar.gz" ]; then
        bbfatal "node_modules.tar.gz not found in ${UNPACKDIR}/webui-libs. \
Ensure webui-libraries repository contains this archive."
    fi

    bbplain "Extracting vendored node_modules from ${UNPACKDIR}/webui-libs/node_modules.tar.gz"
    rm -rf "${S}/node_modules"
    tar -xzf "${UNPACKDIR}/webui-libs/node_modules.tar.gz" -C "${S}"

    if [ ! -d "${S}/node_modules" ]; then
        bbfatal "node_modules directory not found after extraction. \
Check the archive structure in node_modules.tar.gz."
    fi

    bbplain "node_modules successfully extracted"
}

do_compile() {
    cd ${S}

    if [ ! -d "${S}/node_modules" ]; then
        bbfatal "node_modules missing in ${S}. Re-run do_configure to extract dependencies."
    fi

    # Build the Vue project using vendored dependencies - no npm install
    npm run build ${EXTRA_OENPM}
}
