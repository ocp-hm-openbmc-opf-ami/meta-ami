FILESEXTRAPATHS:append := "${THISDIR}/${PN}:"

SRC_URI += " \
        file://0001-Apply-power-restore-policy-only-AC-power-loss.patch \
        file://0002-Timer-Support-for-Chassis-Systems-Reset-EGS.patch \
        "
DEPENDS += "bmc-boot-check"

SRC_URI_EGS:append = "file://0003-Not-able-to-do-power-cycle-if-one-task-is-in-running.patch"

SRC_URI_BHS:append = "file://0003-Not-able-to-do-power-cycle-if-one-task-is-in-running.patch"

EVB:append = "file://0003-Fixed-OT_AST2600EVB_FULL1-build-break.patch"

SRC_URI:append = "${@bb.utils.contains('BBFILE_COLLECTIONS', 'egs', SRC_URI_EGS, '', d)}"
SRC_URI:append = "${@bb.utils.contains('BBFILE_COLLECTIONS', 'bhs', SRC_URI_BHS, '', d)}"
SRC_URI:append = "${@bb.utils.contains('BBFILE_COLLECTIONS', 'evb', EVB, '', d)}"

