/*
 * Copyright (c) 2022 ASPEED Technology Inc.
 *
 * SPDX-License-Identifier: MIT
 */

#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include "mailbox_enums.h"
#include "arguments.h"
#include "i2c_utils.h"

void show_info(ARGUMENTS args)
{
	printf("\nPCH/CPU PFM Active SVN               : 0x%02x\n",
			i2cReadByteData(args, MB_PCH_PFM_ACTIVE_SVN));
	printf("PCH/CPU PFM Active Major Version     : 0x%02x\n",
			i2cReadByteData(args, MB_PCH_PFM_ACTIVE_MAJOR_VER));
	printf("PCH/CPU PFM Active Minor Version     : 0x%02x\n",
			i2cReadByteData(args, MB_PCH_PFM_ACTIVE_MINOR_VER));

	printf("BMC PFM Active SVN                   : 0x%02x\n",
			i2cReadByteData(args, MB_BMC_PFM_ACTIVE_SVN));
	printf("BMC PFM Active Major Version         : 0x%02x\n",
			i2cReadByteData(args, MB_BMC_PFM_ACTIVE_MAJOR_VER));
	printf("BMC PFM Active Minor Version         : 0x%02x\n",
			i2cReadByteData(args, MB_BMC_PFM_ACTIVE_MINOR_VER));

#ifdef ENABLE_PFR_SPDM_ATTESTATION
	printf("AFM Active SVN                       : 0x%02x\n",
			i2cReadByteData(args, MB_BMC_AFM_ACTIVE_SVN));
	printf("AFM Active Major Version             : 0x%02x\n",
			i2cReadByteData(args, MB_BMC_AFM_ACTIVE_MAJOR_VER));
	printf("AFM Active Minor Version             : 0x%02x\n",
			i2cReadByteData(args, MB_BMC_AFM_ACTIVE_MINOR_VER));
#endif

	printf("\nPCH/CPU PFM Recovery SVN             : 0x%02x\n",
			i2cReadByteData(args, MB_PCH_PFM_RECOVERY_SVN));
	printf("PCH/CPU PFM Recovery Major Version   : 0x%02x\n",
			i2cReadByteData(args, MB_PCH_PFM_RECOVERY_MAJOR_VER));
	printf("PCH/CPU PFM Recovery Minor Version   : 0x%02x\n",
			i2cReadByteData(args, MB_PCH_PFM_RECOVERY_MINOR_VER));

	printf("BMC PFM Recovery SVN                 : 0x%02x\n",
			i2cReadByteData(args, MB_BMC_PFM_RECOVERY_SVN));
	printf("BMC PFM Recovery Major Version       : 0x%02x\n",
			i2cReadByteData(args, MB_BMC_PFM_RECOVERY_MAJOR_VER));
	printf("BMC PFM Recovery Minor Version       : 0x%02x\n",
			i2cReadByteData(args, MB_BMC_PFM_RECOVERY_MINOR_VER));

#ifdef ENABLE_PFR_SPDM_ATTESTATION
	printf("AFM Recovery SVN                     : 0x%02x\n",
			i2cReadByteData(args, MB_BMC_AFM_RECOVERY_SVN));
	printf("AFM Recovery Major Version           : 0x%02x\n",
			i2cReadByteData(args, MB_BMC_AFM_RECOVERY_MAJOR_VER));
	printf("AFM Recovery Minor Version           : 0x%02x\n",
			i2cReadByteData(args, MB_BMC_AFM_RECOVERY_MINOR_VER));
#endif
}
