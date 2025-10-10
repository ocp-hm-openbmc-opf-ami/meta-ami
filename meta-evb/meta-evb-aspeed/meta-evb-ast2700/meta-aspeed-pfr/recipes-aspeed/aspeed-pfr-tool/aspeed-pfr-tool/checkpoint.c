/*
 * Copyright (c) 2022 ASPEED Technology Inc.
 *
 * SPDX-License-Identifier: MIT
 */

#include <stdio.h>
#include <stdint.h>
#include <string.h>
#include <openssl/crypto.h>
#include <openssl/ec.h>
#include <openssl/pem.h>
#include <unistd.h>
#include "utils.h"
#include "mailbox_enums.h"
#include "arguments.h"

void checkpointStart(ARGUMENTS args)
{
	WriteByteData(args, MB_BMC_CHECKPOINT, MB_CHKPT_START);
}

void checkpointPause(ARGUMENTS args)
{
	WriteByteData(args, MB_BMC_CHECKPOINT, MB_CHKPT_PAUSE);
}

void checkpointResume(ARGUMENTS args)
{
	WriteByteData(args, MB_BMC_CHECKPOINT, MB_CHKPT_RESUME);
}

void checkpointComplete(ARGUMENTS args)
{
	WriteByteData(args, MB_BMC_CHECKPOINT, MB_CHKPT_COMPLETE);
}

void checkpoint(ARGUMENTS args)
{
	if (strcmp(args.checkpoint_cmd, "start") == 0)
		checkpointStart(args);
	else if (strcmp(args.checkpoint_cmd, "pause") == 0)
		checkpointPause(args);
	else if (strcmp(args.checkpoint_cmd, "resume") == 0)
		checkpointResume(args);
	else if (strcmp(args.checkpoint_cmd, "complete") == 0)
		checkpointComplete(args);
	else
		printf("unsupported command, %s\n", args.checkpoint_cmd);
}

