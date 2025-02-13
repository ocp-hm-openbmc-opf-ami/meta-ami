#!/bin/bash

if [ -f /tmp/.mctp_init_done ];then
	exit 0
fi

cpu_rev_id=$(devmem 0x12c02000 32)
io_rev_id=$(devmem 0x14c02000 32)

# For BMC side spdm attestation emulation
if [[ ${cpu_rev_id} == 0x06000003 && ${io_rev_id} == 0x06000003 ]]; then
    # AST2700-A0
    # BMC i2c10 -> AST1060 i2c5
    mctp link set mctpi2c10 up mtu 68
    mctp addr add 0x0a dev mctpi2c10
    mctp route add 0x0b via mctpi2c10
    mctp neigh add 0x0b dev mctpi2c10 lladdr 0x38
else
    # AST2700-Ax
    # BMC i2c11 -> AST1060 i2c0
    mctp link set mctpi2c11 up mtu 68
    mctp addr add 0x0a dev mctpi2c11
    mctp route add 0x0b via mctpi2c11
    mctp neigh add 0x0b dev mctpi2c11 lladdr 0x38
fi

# For PCH side spdm attestation emulation
# BMC i2c15 -> AST1060 i2c2
mctp link set mctpi2c15 net 2 up mtu 68
mctp addr add 0x0a dev mctpi2c15
mctp route add 0x0b via mctpi2c15
mctp neigh add 0x0b dev mctpi2c15 lladdr 0x70

touch /tmp/.mctp_init_done
