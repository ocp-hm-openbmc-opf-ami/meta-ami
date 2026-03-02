FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

EXTRA_OEMESON += "-Dredfish-dump-log=enabled"
EXTRA_OEMESON += "-Dredfish-new-powersubsystem-thermalsubsystem=enabled"
EXTRA_OEMESON += "-Dredfish-provisioning-feature=enabled"
EXTRA_OEMESON += "-Dredfish-dbus-log=enabled"

# add "redfish-hostiface" group
GROUPADD_PARAM:${PN}:append = ";redfish-hostiface"

SRC_URI = "git://git@github.com/ocp-hm-openbmc-opf-ami/bmcweb;protocol=https;branch=master;name=override;"
SRCREV_FORMAT = "override"
SRCREV_override = "2c03f43dba3f6b295fb175e75194550b64d3bc3f"

EXTRA_OEMESON += "${@bb.utils.contains('IMAGE_FSTYPES', 'intel-pfr', '-Dintel-pfr=enabled',' ', d)}"

EXTRA_OEMESON += "${@bb.utils.contains('IMAGE_FSTYPES', 'intel-pfr', '-Dintel-pfr=enabled',' ', d)}"
EXTRA_OEMESON += "${@bb.utils.contains('BBFILE_COLLECTIONS', 'meta-mgx','-Dredfish-intel-feature=enabled','', d)}"
EXTRA_OEMESON += "${@bb.utils.contains('BBFILE_COLLECTIONS', 'mtmitchell-layer', '-Dredfish-intel-feature=enabled', '', d)}"

DEPENDS += "phosphor-snmp"

do_configure:append() {
    bbplain "****************************** Features Enabled in This Firmware Image ***********************************************"
    i=1
    for feature in ${EXTRA_IMAGE_FEATURES}; do
        i=$(expr "$i" + 1)
    done

    bbplain "Total Feature Count = $i "

    bbplain "*****************************************************************************"

    rm -f "${S}/config/amiconfig.h"
    touch "${S}/config/amiconfig.h"

    i=1
    j=1
    for feature in ${EXTRA_IMAGE_FEATURES}; do
        ENV_VAR_NAME=$(echo "$feature" | tr '[:lower:]' '[:upper:]' | tr '-' '_')
	ENV_LINE="#define ${ENV_VAR_NAME} true"

        if [ $i -eq 1 ]; then
            echo "" >> ${S}/config/amiconfig.h
        fi

        if ! grep -q "^${ENV_LINE}$" ${S}/config/amiconfig.h; then
            echo "${ENV_LINE}" >> ${S}/config/amiconfig.h
	    j=$(expr "$j" + 1)
        else
            bbwarn "Skipped (Duplicate feature already exists): $i. ${ENV_LINE}"
        fi
        i=$(expr "$i" + 1)
    done

    bbwarn "Generated environment variables in amiconfig.h file with $j Features"

}

