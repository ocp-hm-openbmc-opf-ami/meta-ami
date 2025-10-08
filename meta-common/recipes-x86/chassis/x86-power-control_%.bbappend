FILESEXTRAPATHS:append := "${THISDIR}/${PN}:"

SRC_URI += " \
        file://0001-Apply-power-restore-policy-only-AC-power-loss.patch \
        file://0002-Timer-Support-for-Chassis-Systems-Reset-EGS.patch \
        file://0008-Added-changes-for-deleting-the-bootstrap-user-accoun.patch \
        file://0004-Add-Task-interface-and-property.patch \
        file://0003-egs-Not-able-to-do-power-cycle-if-one-task-is-in-running.patch \
        file://0010-Adding-proper-timer-checkout-for-reset-actions.patch \
        file://0006-Generating-a-signal-for-power-operations.patch \
        "

#SRCREV = "58232256fdd892e0a6193c5dd3a0dc5aab2b6477"

SRCREV = "a0a39f82d8299ab4959d1765d56ba614c36236eb"

DEPENDS += "bmc-boot-check"


SRC_URI_AMD:append = "file://0001-AMD-Power-Control.patch"


#EVB:append = "file://0003-evb-Not-able-to-do-power-cycle-if-one-task-is-in-running.patch"

SRC_URI:append = "${@bb.utils.contains('BBFILE_COLLECTIONS', 'amd-chalupa', SRC_URI_AMD, '', d)}"
#SRC_URI:append = "${@bb.utils.contains('BBFILE_COLLECTIONS', 'evb-ast2600', EVB, '', d)}"

SRC_URI_EVB:append =  " \
            file://0011-Coverity-Fix-EVB.patch \
            "
SRC_URI:append = "${@bb.utils.contains('BBFILE_COLLECTIONS', 'evb', SRC_URI_EVB, '', d)}"
SRC_URI:append = "${@bb.utils.contains('BBFILE_COLLECTIONS', 'ast2700-sdk-layer', SRC_URI_EVB, '', d)}"
SRC_URI:append = "${@bb.utils.contains('BBFILE_COLLECTIONS', 'ast2700-pfr-layer', SRC_URI_EVB, '', d)}"
SRC_URI:remove = "${@bb.utils.contains('BBFILE_COLLECTIONS', 'amd-chalupa', 'file://0011-Coverity-Fix-EVB.patch', '', d)}"

SRC_URI_AMD:append =  " \
            file://0011-Coverity-Fix-AMD.patch \
            "

SRC_URI_BHS:append =  " \
            file://0011-Coverity-Fix.patch \
            "
SRC_URI:append = "${@bb.utils.contains('BBFILE_COLLECTIONS', 'bhs', SRC_URI_BHS, '', d)}"
