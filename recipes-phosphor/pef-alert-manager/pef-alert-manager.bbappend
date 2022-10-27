FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"
PROJECT_SRC_DIR := "${THISDIR}/${PN}"

SRC_URI += "file://0001-fix-sensornumber-mapping.patch \
            file://0002-Fix-Wrong-SensorName-issue.patch \
        "
