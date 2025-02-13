/*
 * Copyright (c) 2022 ASPEED Technology Inc.
 *
 * SPDX-License-Identifier: MIT
 */

#pragma once

typedef struct _ARGUMENTS {
	int i2c_fd;
	uint8_t i2c_bus;
	uint8_t rot_addr;
	uint8_t debug_flag;
	int lms_mode;
	uint32_t bmc_active_pfm_offset;
	uint32_t bmc_staging_offset;
	uint32_t bmc_recovery_offset;
	uint32_t pch_active_pfm_offset;
	uint32_t pch_staging_offset;
	uint32_t pch_recovery_offset;
	uint8_t tx_msg[64];
	uint8_t rx_msg[64];
	int tx_msg_len;
	int rx_msg_len;
	char *pfr_tool_conf;
	char *provision_cmd;
	char *checkpoint_cmd;
} ARGUMENTS;

