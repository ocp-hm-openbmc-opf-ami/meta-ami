FILESEXTRAPATHS:append := "${THISDIR}/${PN}:"

SRC_URI += " \
        file://0001-Apply-power-restore-policy-only-AC-power-loss.patch \
        file://0002-Timer-Support-for-Chassis-Systems-Reset-EGS.patch \
        file://0008-Added-changes-for-deleting-the-bootstrap-user-accoun.patch \
        "
SRCREV = "b1e34a11f5c64a7c4225fb4cf15ee7f9368cbef4"

DEPENDS += "bmc-boot-check"

SRC_URI_EGS:append = " \
                      file://0004-Add-Task-interface-and-property.patch \
                      file://0003-egs-Not-able-to-do-power-cycle-if-one-task-is-in-running.patch \
                      file://0005-Power-operation-for-future-time.patch \
                     "

SRC_URI_BHS:append = "file://0003-bhs-Not-able-to-do-power-cycle-if-one-task-is-in-running.patch"

EVB:append = "file://0003-evb-Not-able-to-do-power-cycle-if-one-task-is-in-running.patch"

SRC_URI:append = "${@bb.utils.contains('BBFILE_COLLECTIONS', 'egs', SRC_URI_EGS, '', d)}"
SRC_URI:append = "${@bb.utils.contains('BBFILE_COLLECTIONS', 'bhs', SRC_URI_BHS, '', d)}"
SRC_URI:append = "${@bb.utils.contains('BBFILE_COLLECTIONS', 'evb-ast2600', EVB, '', d)}"

