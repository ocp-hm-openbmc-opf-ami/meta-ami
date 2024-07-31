FILESEXTRAPATHS:append := ":${THISDIR}/files:"
#0003-fix-incompatible-pointer-type-of-i2c-slave-mqueue.patch
SRC_URI += "    file://0001-ast2700_enable_all_uart.patch \
                file://0002-x86-power-control-gpio-config-2700.patch \
                file://nfs_cifs.cfg \
                file://0004-Fix-2700-DTS-for-NCSI.patch \
                file://0005-ip_address_update_ncsi_interface.patch \
                file://0006-Fix-NCSI-Auto-Failover.patch \
           "
