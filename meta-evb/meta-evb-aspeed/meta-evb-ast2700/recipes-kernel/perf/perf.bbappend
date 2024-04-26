#According to the perf.bb, perl package should be removed from perf run-time dependencies if users disable scripting.
#include ${@bb.utils.contains('PACKAGECONFIG', 'scripting', 'perf-perl.inc', '', d)}
#However, this recipe still include perf-perl.inc to install perl package.
#To save the code size, add RDEPENDS:${PN}:remove to remove perl package.
#It is a work around solution.
RDEPENDS:${PN}:remove = "perl"
#PACKAGECONFIG:remove = "scripting"
#EXTRA_OEMAKE:append = " PYTHON=python3 PYTHON_CONFIG=python3-config "
