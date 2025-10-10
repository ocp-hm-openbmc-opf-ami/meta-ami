# Enable downstream autobump
# The URI is required for the autobump script but keep it commented
# to not override the upstream value
# SRC_URI = "git://github.com/openbmc/webui-vue.git;branch=master;protocol=https"
# SRCREV = "f763cd2e39ffce9b10191402243e8704794f08ff"

# AMI own repository for webui-vue with main branch
SRC_URI = "git://git@github.com/ocp-hm-openbmc-opf-ami/webui-vue;protocol=https;branch=main"

# Use AUTOREV to get the latest revision from the repository
# SRCREV = "${AUTOREV}"
SRCREV = "71ca7573230427d2a4c94e380ca7e93f61c23404"

SRC_URI += " \
    file://login-company-logo.svg \
    file://logo-header.svg \
    "
FILESEXTRAPATHS:append := "${THISDIR}/${PN}:"
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

    bbwarn "Generated environment variables in .env file"

    cp -vf ${S}/.env.intel ${S}/.env
    while IFS= read -r line; do
    bbplain "$line"
    done < ${S}/.env.intel
}
