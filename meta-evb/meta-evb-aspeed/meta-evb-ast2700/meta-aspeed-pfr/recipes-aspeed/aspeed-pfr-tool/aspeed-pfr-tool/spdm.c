/*
 * Copyright (c) 2023 ASPEED Technology Inc.
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

void setSPDMFunction(ARGUMENTS args, int enabled)
{
	if (enabled)
	{
		i2cWriteByteData(args, 0xb, 0x12);
		printf("SPDM is enabled\n");
	}
	else
	{
		i2cWriteByteData(args, 0xb, 0x14);
		printf("SPDM is disabled\n");
	}
	i2cWriteByteData(args, 0xc, 0x1);
}

