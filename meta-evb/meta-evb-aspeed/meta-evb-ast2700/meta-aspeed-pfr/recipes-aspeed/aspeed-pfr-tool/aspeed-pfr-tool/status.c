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
#include "provision.h"

static const char *g_plat_state[256] = {
	"Unknown",
	"CPLD waiting to start",
	"CPLD started",
	"Enter T-1",
	"", // T-1 Reserved
	"", // T-1 Reserved
	"BMC flash authentication",
	"PCH/CPU flash authentication",
	"Lockdown due to authentication failure",
	"Enter T0",
	"T0 BMC booted",
	"T0 Intel ME booted",
	"T0 ACM booted",
	"T0 BIOS booted",
	"T0 boot completed",
	"", //T0 Reserved
	"PCH/CPU firmware udpate",
	"BMC firmware update",
	"CPLD active update",
	"CPLD rom update",
	"PCH/CPU firmware volume update",
	"PCH/CPU firmware volume update completed",
	"SCM booted from Active CFM1/2",
	"CPU CPLD booted from Active CFM1/2",
	"Debug CPLD booted from Active CFM1/2",
	"SCM/CPU/Debug CPLD image update",
	// 1Ah - 1Fh Reserved
	"", "", "", "", "", "",
	// 20 - 2Fh Reserved
	"", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "",
	// 30 - 3Fh Reserved
	"", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "",
	"T-1 firmware recovery due to authentication failure",
	"T-1 forced active firmware recovery",
	"Watchdog timer timeout recovery",
	"CPLD recovery",
	"Lockdown due to PIT L1",
	"PIT L2 firmware sealed",
	"Lockdown due to PIT L2 PCH/CPU firmware hash mismatch",
	"Lockdown due to PIT L2 BMC firmware hash mismatch",
	// 48h - 4Fh Reserved
	"", "", "", "", "", "", "", "",
	// 50h - 5Fh Reserved
	"", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "",
	// 60h - 6Fh Reserved
	"", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "",
	// 70h - 7Fh Reserved
	"", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "",
	// 80h - 8Fh Reserved
	"", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "",
	// 90h - 9Fh Reserved
	"", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "",
	// A0h - AFh Reserved
	"", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "",
	// B0h - BFh Reserved
	"", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "",
	// C0h - CFh Reserved
	"", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "",
	// D0h - DFh Reserved
	"", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "",
	// E0h - EFh Reserved
	"", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "",
	// F0h - FFh Reserved
	"", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "",
};

static const char *g_last_recovery_reason[256] = {
	"N/A",
	"PCH/CPU active failure",
	"PCH/CPU recovery failure",
	"Intel ME launch failure",
	"ACM launch failure",
	"IBB launch failure",
	"OBB launch failure",
	"BMC active failure",
	"BMC recovery failure",
	"BMC launch failure",
	"CPLD WDT expired forced active fw recovery",
	"CPLD active failure",
	// 0Ch - 0Fh Reserved
	"", "", "", "",
	// 10h - 1Fh Reserved
	"", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "",
	// 20h - 2Fh Reserved
	"", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "",
	// 30h - 3Fh Reserved
	"", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "",
	// 40h - 4Fh Reserved
	"", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "",
	// 50h - 5Fh Reserved
	"", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "",
	// 60h - 6Fh Reserved
	"", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "",
	// 70h - 7Fh Reserved
	"", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "",
	// 80h - 8Fh Reserved
	"", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "",
	// 90h - 9Fh Reserved
	"", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "",
	// A0h - AFh Reserved
	"", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "",
	// B0h - BFh Reserved
	"", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "",
	// C0h - CFh Reserved
	"", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "",
	// D0h - DFh Reserved
	"", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "",
	// E0h - EFh Reserved
	"", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "",
	// F0h - FFh Reserved
	"", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "",
};

static const char *g_last_panic_reason[256] = {
	"N/A",
	"PCH update intent",
	"BMC update intent",
	"BMC reset detected",
	"BMC WDT expired",
	"Intel ME WDT expired",
	"ACM WDT expired",
	"IBB WDT expired",
	"OBB WDT expired",
	"ACM/IBB/OBB sigled authentication failure",
	"Attestation failure",
	// 0Bh - 0Fh Reserved
	"", "", "", "", "",
	// 10h - 1Fh Reserved
	"", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "",
	// 20h - 2Fh Reserved
	"", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "",
	// 30h - 3Fh Reserved
	"", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "",
	// 40h - 4Fh Reserved
	"", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "",
	// 50h - 5Fh Reserved
	"", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "",
	// 60h - 6Fh Reserved
	"", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "",
	// 70h - 7Fh Reserved
	"", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "",
	// 80h - 8Fh Reserved
	"", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "",
	// 90h - 9Fh Reserved
	"", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "",
	// A0h - AFh Reserved
	"", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "",
	// B0h - BFh Reserved
	"", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "",
	// C0h - CFh Reserved
	"", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "",
	// D0h - DFh Reserved
	"", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "",
	// E0h - EFh Reserved
	"", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "",
	// F0h - FFh Reserved
	"", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "",
};

static const char *g_major_err[256] = {
	"N/A",
	"BMC authentication filure",
	"PCH/CPU authentication filure",
	"in-band and OOB update filure (BMC or PCH or ROT)",
	"ROT authentication filaure",
	"Attestation measurement mismatch-Attestation failure",
	"Attestation Challenge timeout",
	"SPDM Protocol Error",
	"CPU/SCM/Debug CPLD Authentication failure",
	// 09h - 0Fh Reserved
	"", "", "", "", "", "", "",
	// 10h - 1Fh Reserved
	"", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "",
	// 20h - 2Fh Reserved
	"", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "",
	// 30h - 3Fh Reserved
	"", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "",
	// 40h - 4Fh Reserved
	"", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "",
	// 50h - 5Fh Reserved
	"", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "",
	// 60h - 6Fh Reserved
	"", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "",
	// 70h - 7Fh Reserved
	"", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "",
	// 80h - 8Fh Reserved
	"", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "",
	// 90h - 9Fh Reserved
	"", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "",
	// A0h - AFh Reserved
	"", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "",
	// B0h - BFh Reserved
	"", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "",
	// C0h - CFh Reserved
	"", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "",
	// D0h - DFh Reserved
	"", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "",
	// E0h - EFh Reserved
	"", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "",
	// F0h - FFh Reserved
	"", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "",
};

static const char *g_minor_auth_err[256] = {
	"N/A",
	"Active region authentication failure",
	"Recovery region authentication failure",
	"Active and Recovery region authentication failure",
	"Active, Recovery and Staging region authentication failure",
	"AFM Active region authentication failure",
	"AFM Recovery region authentication failure",
	"AFM Active and Recovery region authentication failure",
	"AFM Active, Recovery and Staging region authentication failure",
	// 09h - 0Fh Reserved
	"", "", "", "", "", "", "",
	// 10h - 1Fh Reserved
	"", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "",
	// 20h - 2Fh Reserved
	"", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "",
	// 30h - 3Fh Reserved
	"", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "",
	// 40h - 4Fh Reserved
	"", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "",
	// 50h - 5Fh Reserved
	"", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "",
	// 60h - 6Fh Reserved
	"", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "",
	// 70h - 7Fh Reserved
	"", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "",
	// 80h - 8Fh Reserved
	"", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "",
	// 90h - 9Fh Reserved
	"", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "",
	// A0h - AFh Reserved
	"", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "",
	// B0h - BFh Reserved
	"", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "",
	// C0h - CFh Reserved
	"", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "",
	// D0h - DFh Reserved
	"", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "",
	// E0h - EFh Reserved
	"", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "",
	// F0h - FFh Reserved
	"", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "",
};

static const char *g_minor_update_err[256] = {
	"N/A",
	"Invalid update intent",
	"Update capsule has invalid SVN",
	"Update capsule failed authentication",
	"Exceeded maximum failed update attempts",
	"Active firmware update is not allowed because the recovery region failed authentication in T-1",
	"FW update capsule failed authentication before being promoted to recovery region",
	"AFM update is not allowed",
	"Unknown AFM",
	// 09h - 0Fh Reserved
	"", "", "", "", "", "", "",
	"Unknown FV type",
	"Authentication filed after seamless update",
	// 12h - 1Fh Reserved
	"", "", "", "", "", "", "", "", "", "", "", "", "", "",
	// 20h - 2Fh Reserved
	"", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "",
	// 30h - 3Fh Reserved
	"", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "",
	// 40h - 4Fh Reserved
	"", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "",
	// 50h - 5Fh Reserved
	"", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "",
	// 60h - 6Fh Reserved
	"", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "",
	// 70h - 7Fh Reserved
	"", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "",
	// 80h - 8Fh Reserved
	"", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "",
	// 90h - 9Fh Reserved
	"", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "",
	// A0h - AFh Reserved
	"", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "",
	// B0h - BFh Reserved
	"", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "",
	// C0h - CFh Reserved
	"", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "",
	// D0h - DFh Reserved
	"", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "",
	// E0h - EFh Reserved
	"", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "",
	// F0h - FFh Reserved
	"", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "",
};

static const char *g_ufm_provisioning_status[8] = {
	"Bit[0]: Command Busy",
	"Bit[1]: Command Done",
	"Bit[2]: Command Error",
	"Bit[3]: Reserved",
	"Bit[4]: UFM locked",
	"Bit[5]: UFM Provisioned",
	"Bit[6]: PIT Level-1 enforced",
	"Bit[7]: PIT Level-2 has been completed successfully",
};
static const char *g_pfr_activity_info1[8] = {
	"Bit[0]: I3C DAA (BMC)",
	"Bit[1]: I3C Set EID (BMC)",
	"Bit[2]: I3C EID Registration (BMC)",
	"Bit[3]: I3C MUX Takeover",
	"Bit[4]: I3C DAA (CPU)",
	"Bit[5]: I3C Set EID (CPU)",
	"Bit[6]: I3C EID Registration (CPU)",
	"Reserved",
};

static const char *g_pfr_activity_info2[8] = {
	"Bit[0]: BMC Boot Done",
	"Bit[1]: IBB Boot Done",
	"Bit[2]: OBB Boot Done",
	"Reserved",
	"Reserved",
	"Reserved",
	"Reserved",
	"Reserved",
};

static const char *g_pfr_activity_unknown = "Unkown";

static uint8_t get_cpld_id(ARGUMENTS args)
{
	return i2cReadByteData(args, MB_CPLD_STATIC_ID);
}

static uint8_t get_cpld_ver(ARGUMENTS args)
{
	return i2cReadByteData(args, MB_CPLD_RELEASE_VERSION);
}

static uint8_t get_cpld_svn(ARGUMENTS args)
{
	return i2cReadByteData(args, MB_CPLD_SVN);
}

static const char *get_plat_state(ARGUMENTS args, uint8_t *pstate)
{
	*pstate = i2cReadByteData(args, MB_PLATFORM_STATE);
	return g_plat_state[*pstate];
}

static uint8_t get_recovery_count(ARGUMENTS args)
{
	return i2cReadByteData(args, MB_RECOVERY_COUNT);
}

static const char *get_last_recovery_reason(ARGUMENTS args, uint8_t *last_recovery_reason)
{
	*last_recovery_reason = i2cReadByteData(args, MB_LAST_RECOVERY_REASON);
	return g_last_recovery_reason[*last_recovery_reason];
}

static uint8_t get_panic_event_count(ARGUMENTS args)
{
	return i2cReadByteData(args, MB_PANIC_EVENT_COUNT);
}

static const char *get_last_panic_reason(ARGUMENTS args, uint8_t *last_panic_reason)
{
	*last_panic_reason = i2cReadByteData(args, MB_LAST_PANIC_REASON);
	return g_last_panic_reason[*last_panic_reason];
}

static const char *get_major_err(ARGUMENTS args, uint8_t *major_err)
{
	 *major_err = i2cReadByteData(args, MB_MAJOR_ERROR_CODE);
	return g_major_err[*major_err];
}

static const char *get_minor_auth_err(ARGUMENTS args, uint8_t *minor_err)
{
	*minor_err = i2cReadByteData(args, MB_MINOR_ERROR_CODE);
	return g_minor_auth_err[*minor_err];
}

static const char *get_minor_update_err(ARGUMENTS args, uint8_t *minor_err)
{
	*minor_err = i2cReadByteData(args, MB_MINOR_ERROR_CODE);
	return g_minor_update_err[*minor_err];
}

static void get_ufm_provisioning_status(ARGUMENTS args, uint8_t *ufm_provisioning_status_code, char *ufm_provisioning_status)
{
	uint8_t status;
	int i;

	*ufm_provisioning_status_code = i2cReadByteData(args, MB_PROVISION_STATUS);
	status = *ufm_provisioning_status_code;

	for (i = 0; i < 8; i++) {
		if (status & 0x01) {
			strcat(ufm_provisioning_status, g_ufm_provisioning_status[i]);
			strcat(ufm_provisioning_status, "\n");
			strcat(ufm_provisioning_status, "                               ");
		}
		status >>= 1;
	}
}

static const char *get_pfr_activity_1(ARGUMENTS args, uint8_t *activity)
{
	uint8_t i, stat;

	*activity = i2cReadByteData(args, MB_PFR_ACTIVITY_INFO_1);
	stat = *activity;

	for (i = 0; i < 8; i++) {
		if (stat & 1)
			return g_pfr_activity_info1[i];
		stat >>= 1;
	}

	return g_pfr_activity_unknown;
}

static const char *get_pfr_activity_2(ARGUMENTS args, uint8_t *activity)
{
	uint8_t i, stat;

	*activity = i2cReadByteData(args, MB_PFR_ACTIVITY_INFO_2);
	stat = *activity;

	for (i = 0; i < 8; i++) {
		if (stat & 1)
			return g_pfr_activity_info2[i];
		stat >>= 1;
	}

	return g_pfr_activity_unknown;
}

static void get_cpld_hash(ARGUMENTS args, uint8_t *hash_buf, uint8_t len)
{
	int i;

	for (i = 0; i < len; i++)
		hash_buf[i] = i2cReadByteData(args, MB_CPLD_HASH + i);
}

void show_status(ARGUMENTS args)
{
	uint8_t pstate_code;
	uint8_t rc_reason_code;
	uint8_t panic_reason_code;
	uint8_t major_err_code;
	uint8_t minor_err_code;
	uint8_t ufm_provisioning_status_code;
	uint8_t pfr_activity_1_code;
	uint8_t pfr_activity_2_code;
	const char *plat_state;
	const char *last_rc_reason;
	const char *panic_reason;
	const char *major_err;
	const char *minor_err;
	const char *pfr_activity_1;
	const char *pfr_activity_2;
	char ufm_provisioning_status[2048] = { 0 };
	uint8_t hash_buf[SHA512_LENGTH] = { 0 };
	int i;

	printf("\nCPLD Rot Static Identifier   : 0x%02x\n", get_cpld_id(args));
	printf("CPLD Rot Release Version     : 0x%02x\n", get_cpld_ver(args));
	printf("CPLD Rot SVN                 : 0x%02x\n", get_cpld_svn(args));
	printf("CPLD Rot Hash                : ");

	get_cpld_hash(args, hash_buf, SHA512_LENGTH);
	for (i = 0; i < SHA512_LENGTH; ++i) {
		printf("%02x ", hash_buf[i]);
		if ((i+1)%16 == 0) {
			printf("\n");
			printf("                               ");
		}
	}
	printf("\n");

	plat_state = get_plat_state(args, &pstate_code);
	printf("Platform State Code          : 0x%02x\n", pstate_code);
	printf("Platform State               : %s\n\n", plat_state);

	printf("Recovery Count               : %d\n", get_recovery_count(args));

	last_rc_reason = get_last_recovery_reason(args, &rc_reason_code);
	printf("Last Recovery Reason Code    : 0x%02x\n", rc_reason_code);
	printf("Last Recovery Reason         : %s\n\n", last_rc_reason);

	printf("Panic Event Count            : %d\n", get_panic_event_count(args));
	panic_reason = get_last_panic_reason(args, &panic_reason_code);
	printf("Last Panic Reason Code       : 0x%02x\n", panic_reason_code);
	printf("Last Panic Reason            : %s\n\n", panic_reason);

	major_err = get_major_err(args, &major_err_code);
	printf("Major Error Code             : 0x%02x\n", major_err_code);
	printf("Major Error                  : %s\n\n", major_err);

	if (major_err_code <= 2)
		minor_err = get_minor_auth_err(args, &minor_err_code);
	else
		minor_err = get_minor_update_err(args, &minor_err_code);
	printf("Minor Error Code             : 0x%02x\n", minor_err_code);
	printf("Minor Error                  : %s\n\n", minor_err);

	pfr_activity_1 = get_pfr_activity_1(args, &pfr_activity_1_code);
	printf("PFR Activity Info 1 Code     : 0x%02x\n", pfr_activity_1_code);
	printf("PFR Activity Info 1          : %s\n\n", pfr_activity_1);

	pfr_activity_2 = get_pfr_activity_2(args, &pfr_activity_2_code);
	printf("PFR Activity Info 2 Code     : 0x%02x\n", pfr_activity_2_code);
	printf("PFR Activity Info 2          : %s\n\n", pfr_activity_2);

	get_ufm_provisioning_status(args, &ufm_provisioning_status_code, ufm_provisioning_status);
	printf("UFM/Provisioning Status Code : 0x%02x\n", ufm_provisioning_status_code);
	printf("UFM/Provisioning Status      : %s\n\n", ufm_provisioning_status);
}
