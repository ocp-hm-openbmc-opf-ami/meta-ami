FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

#SRCREV = "8dc277cc790efa2a25a4778693cba1bfa24ab741"

SRCREV = "bd63bcaca2ac9edf1778136cf240e3bbe8b31566"


SRC_URI:append = " \
                 file://0001-Thermal-OEM-condtions-Feature-Enhancement.patch \
                 file://0002-Increasing-the-Poll-Rate-for-CPU-Usage.patch \
		 file://0003-MSFT-Phosphor-pid-control-Intergration.patch \
                 file://0004-Coverity-fix.patch \
                 file://0005-Added-the-Condition-to-handle-the-journal-log.patch \
                 file://0006-Optimizing-the-Thermal-OEM-Conditions-code.patch \
                 file://0007-Removing-the-debug-print.patch \
                 "



