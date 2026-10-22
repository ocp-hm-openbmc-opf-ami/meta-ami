PACKAGECONFIG:append = " log-threshold log-alarm log-watchdog send-to-logger"

DEPENDS:remove = "intel-ipmi-oem-ext"
RDEPENDS:${PN}:remove = "intel-ipmi-oem-ext"

# Strip the Intel-specific AMI fork from SRC_URI and revert to the upstream
# source from the base recipe. The AMI fork requires intel-ipmi-oem/sdrutils.hpp
# which is not available on NXP platforms (intel-ipmi-oem-ext is SKIP_RECIPE'd).
# SRC_URI:remove is a post-assignment operation and reliably strips the value
# regardless of how (+=, :append, direct =) it was added by lower-priority layers.
SRC_URI:remove = "git://git@github.com/ocp-hm-openbmc-opf-ami/phosphor-sel-logger.git;branch=master;protocol=https;name=override;"
SRCREV_FORMAT = ""
SRCREV = "5bafde6f7769e314feb7d091d50f20f6631fbb06"

# Remove Intel-specific meson options added by AMI common bbappend.
# meta-ami (BBFILE_PRIORITY=14) is applied AFTER meta-nxp (BBFILE_PRIORITY=6), so
# direct varflag assignments like PACKAGECONFIG[log-crash]="" cannot win.
# However, meson.bbclass does "EXTRA_OEMESON:append = ${PACKAGECONFIG_CONFARGS}",
# so all PACKAGECONFIG flags (including the "without" arg -Dlog-crash=false)
# end up in EXTRA_OEMESON. The :remove post-operator strips them from the final
# assembled string regardless of how/when they were added.
EXTRA_OEMESON:remove = "-Dsel-extended=true"
EXTRA_OEMESON:remove = "-Dlog-crash=false"
EXTRA_OEMESON:remove = "-Dsel-delete=true"
EXTRA_OEMESON:remove = "-Dsel-delete=false"
PACKAGECONFIG:remove = "log-crash"

EXTRA_OEMESON:remove = "-Dstatic-sensor-number=true"
EXTRA_OEMESON:remove = "-Dstatic-sensor-number=false"
