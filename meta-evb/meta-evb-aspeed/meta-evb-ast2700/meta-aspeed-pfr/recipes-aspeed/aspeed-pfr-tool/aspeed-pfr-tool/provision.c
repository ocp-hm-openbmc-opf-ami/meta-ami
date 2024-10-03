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
#include "provision.h"
#include "i2c_utils.h"
#include "mailbox_enums.h"
#include "arguments.h"

int extractQxQyFromPubkey(const char *file, uint8_t *qx, uint8_t *qy, int *len)
{
#if (OPENSSL_VERSION_NUMBER < 0x30000000L)
	EC_KEY * eckey = NULL;
#else
	EVP_PKEY * eckey = NULL;
#endif
	uint8_t *pub = NULL;
	int ret = 1;
	int publen;
	int i;
	int j;

	if (file == NULL) {
		printf("%s, File is NULL.\n", __func__);
		return ret;
	}

	BIO * in = BIO_new_file(file, "r");

	if (in == NULL) {
		printf("%s, Failed to read eckey %s.\n", __func__, file);
		goto bio;
	}

#if (OPENSSL_VERSION_NUMBER < 0x30000000L)
	eckey = PEM_read_bio_EC_PUBKEY(in, NULL, NULL, NULL);

	if (eckey == NULL) {
		printf("%s, Failed to read eckey %s.\n", __func__, file);
		goto bio;
	}

	publen = EC_KEY_key2buf(eckey, EC_KEY_get_conv_form(eckey), &pub, NULL);
#else
	eckey = PEM_read_bio_PUBKEY(in, NULL, NULL, NULL);

	if (eckey == NULL) {
		printf("%s, Failed to read eckey %s.\n", __func__, file);
		goto bio;
	}

	publen = EVP_PKEY_get1_encoded_public_key(eckey, &pub);
#endif
	if (pub[0] != 0x04) {
		// key is compressed, we don't support this
		printf("%s, Key is in compressed format. This is currently not supported.\n", __func__);
		goto bio;
	}

	*len = (publen - 1) / 2;

	// set qx and qy
	for (i = 1, j = 0; j < *len; ++i, ++j)
		qx[j] = pub[i];

	for (i = *len + 1, j = 0; j < *len; ++i, ++j)
		qy[j] = pub[i];

	ret = 0;

bio:
	BIO_free(in);
	return ret;
}

int hashBuffer(const uint8_t *buffer, const int bufSize, const HashAlg hashAlg,
	uint8_t *hash, int *size)
{
	EVP_MD_CTX *mctx = NULL;
	const EVP_MD *md = NULL;
	int ret = 1;

	// check for any NULLs
	if (buffer == NULL || hash == NULL || size == NULL) {
		printf("%s, Buffer, hash or size is NULL.\n", __func__);
		return ret;
	}

	if (hashAlg == Sha256) {
		*size = SHA256_DIGEST_LENGTH;
		md = EVP_sha256();
	} else if (hashAlg == Sha384) {
		*size = SHA384_DIGEST_LENGTH;
		md = EVP_sha384();
	} else if (hashAlg == Sha512) {
		*size = SHA512_DIGEST_LENGTH;
		md = EVP_sha512();
	}

	mctx = EVP_MD_CTX_new();
	EVP_DigestInit_ex(mctx, md, NULL);
	ret = EVP_DigestUpdate(mctx, buffer, bufSize);

	// Final frees mctx memory
	if (ret != 0 && EVP_DigestFinal_ex(mctx, hash, (unsigned int *)size) <= 0) {
		printf("%s, Failed to generate hash.\n", __func__);
		ret = 1;
	}

	EVP_MD_CTX_free(mctx);
	return ret;
}

int getRootKeyHash(const char *file, uint8_t *hash, int *len)
{
	uint8_t pubkey_x[SHA384_LENGTH];
	uint8_t pubkey_y[SHA384_LENGTH];
	uint8_t buffer[SHA384_LENGTH*2];
	int size = 0;
	int i;

	if (extractQxQyFromPubkey(file, pubkey_x, pubkey_y, &size)) {
		printf("%s, Failed to extract QX and QY.\n", __func__);
		return 1;
	}

	if ((size == SHA256_LENGTH) || (size == SHA384_LENGTH)) {
		// Collect root public key X and Y, in little endian byte order.
		for (i = 0; i < size; i++) {
			buffer[i] = pubkey_x[size - 1 - i];
			buffer[i + size] = pubkey_y[size - 1 - i];
		}

		if (size == SHA256_LENGTH)
			hashBuffer(buffer, size*2, Sha256, hash, len);
		else
			hashBuffer(buffer, size*2, Sha384, hash, len);
	} else {
		printf("%s, Unsuported key size.\n", __func__);
		return 1;
	}

	return 0;
}

int getLMSRootKeyHash(const char *file, HashAlg type, uint8_t *hash, int *len)
{
	uint8_t buffer[SHA384_LENGTH*2];
	int rlen;
	FILE *fp;

	fp = fopen(file, "r+");
	if (fp) {
		rlen = fread(buffer, 1, sizeof(buffer), fp);
		fclose(fp);
		if (rlen <= 0) {
			printf("failed to read public key (%s)\n", file);
			return -1;
		}
	} else
		printf("failed to open public key (%s)\n", file);

	if (type == Sha256)
		hashBuffer(buffer, rlen, Sha256, hash, len);
	else
		hashBuffer(buffer, rlen, Sha384, hash, len);

	return 0;
}

int waitUntilUfmCmdTriggerExec(ARGUMENTS args)
{
	uint8_t read_reg_value;
	uint8_t mask = MB_UFM_CMD_EXECUTE_MASK | MB_UFM_CMD_FLUSH_WR_FIFO_MASK | MB_UFM_CMD_FLUSH_RD_FIFO_MASK;
	int i = 0;

	while (i < 100) {
		read_reg_value = i2cReadByteData(args, MB_UFM_CMD_TRIGGER);
		if (read_reg_value & mask) {
			if (args.debug_flag)
				printf("UFM Command Trigger: Not execute, wait 20ms %d time\n", i);
		} else
			return 0;
		usleep(20*1000);
		i++;
	}

	printf("UFM Command Trigger: Not execute(TimeOut)\n");
	return 1;
}

int waitUntilUfmProvStatusCmdDone(ARGUMENTS args)
{
	uint8_t read_reg_value;
	int i = 0;

	while (i < 100) {
		read_reg_value = i2cReadByteData(args, MB_PROVISION_STATUS);
		if (read_reg_value & MB_UFM_PROV_CMD_BUSY_MASK) {
			if (args.debug_flag)
				printf("UFM Provisioning Status: Command busy..., wait 20ms %d time\n", i);
		} else {
			if (read_reg_value & MB_UFM_PROV_CMD_DONE_MASK) {
				if (read_reg_value & MB_UFM_PROV_CMD_ERROR_MASK) {
					printf("UFM Provisioning Status: Command error\n");
					return 1;
				}
				return 0;
			}
		}
		usleep(20*1000);
		i++;
	}

	printf("UFM Command Trigger: Command busy(TimeOut)\n");
	return 1;
}


int writeUfmProvFifoCmd(ARGUMENTS args, MB_UFM_PROV_CMD_ENUM cmd, uint8_t *buf, int len)
{
	int i;

	// Flush Write FIFO
	i2cWriteByteData(args, MB_UFM_CMD_TRIGGER, MB_UFM_CMD_FLUSH_WR_FIFO_MASK);
	if (waitUntilUfmCmdTriggerExec(args) || waitUntilUfmProvStatusCmdDone(args))
		return 1;

	// Write FIFO
	for (i = 0; i < len; i++)
		i2cWriteByteData(args, MB_UFM_WRITE_FIFO, buf[i]);

	// Trigger command
	i2cWriteByteData(args, MB_PROVISION_CMD, cmd);
	i2cWriteByteData(args, MB_UFM_CMD_TRIGGER, MB_UFM_CMD_EXECUTE_MASK);
	if (waitUntilUfmCmdTriggerExec(args) || waitUntilUfmProvStatusCmdDone(args))
		return 1;

	return 0;
}

int readUfmProvFifoCmd(ARGUMENTS args, MB_UFM_PROV_CMD_ENUM cmd, uint8_t *buf, int len)
{
	int i;

	// Flush Read FIFO
	i2cWriteByteData(args, MB_UFM_CMD_TRIGGER, MB_UFM_CMD_FLUSH_RD_FIFO_MASK);
	if (waitUntilUfmCmdTriggerExec(args) || waitUntilUfmProvStatusCmdDone(args))
		return 1;

	// Trigger command
	i2cWriteByteData(args, MB_PROVISION_CMD, cmd);
	i2cWriteByteData(args, MB_UFM_CMD_TRIGGER, MB_UFM_CMD_EXECUTE_MASK);
	if (waitUntilUfmCmdTriggerExec(args) || waitUntilUfmProvStatusCmdDone(args))
		return 1;

	// Read FIFO
	for (i = 0; i < len; i++)
		buf[i] = i2cReadByteData(args, MB_UFM_READ_FIFO);

	return 0;
}

int writeUfmProvBmcPchRegionOffset(ARGUMENTS args)
{
	uint8_t bmc_offset[12];
	uint8_t pch_offset[12];

	memcpy(bmc_offset, &args.bmc_active_pfm_offset, 4);
	memcpy(bmc_offset + 4, &args.bmc_recovery_offset, 4);
	memcpy(bmc_offset + 8, &args.bmc_staging_offset, 4);
	memcpy(pch_offset, &args.pch_active_pfm_offset, 4);
	memcpy(pch_offset + 4, &args.pch_recovery_offset, 4);
	memcpy(pch_offset + 8, &args.pch_staging_offset, 4);

	if (args.debug_flag) {
		printf("BMC Offset\n");
		printRawData(bmc_offset, sizeof(bmc_offset));
		printf("PCH Offset\n");
		printRawData(pch_offset, sizeof(pch_offset));
	}

	// Write BMC offset
	if (writeUfmProvFifoCmd(args, MB_UFM_PROV_BMC_OFFSETS, bmc_offset, sizeof(bmc_offset))) {
		printf("Write UFM BMC offset failed\n");
		return 1;
	}

	// Write PCH offset
	if (writeUfmProvFifoCmd(args, MB_UFM_PROV_PCH_OFFSETS, pch_offset, sizeof(pch_offset))) {
		printf("Write UFM PCH offset failed\n");
		return 1;
	}

	return 0;
}

int provisionLock(ARGUMENTS args)
{
	i2cWriteByteData(args, MB_PROVISION_CMD, MB_UFM_PROV_END);
	i2cWriteByteData(args, MB_UFM_CMD_TRIGGER, MB_UFM_CMD_EXECUTE_MASK);
	if (waitUntilUfmCmdTriggerExec(args) || waitUntilUfmProvStatusCmdDone(args)) {
		printf("%s failed\n", __func__);
		return 1;
	}

	printf("%s success\n", __func__);
	return 0;
}

int provisionShow(ARGUMENTS args)
{
	uint8_t read_buf[SHA512_LENGTH];

	// Read BMC offset
	if (readUfmProvFifoCmd(args, MB_UFM_PROV_RD_BMC_OFFSETS, read_buf, 12)) {
		printf("Read UFM BMC offset failed\n");
		return 1;
	}
	printf("BMC Active PFM Offset : 0x%08x\n", *(uint32_t *)&read_buf[0]);
	printf("BMC Recovery Region Offset : 0x%08x\n", *(uint32_t *)&read_buf[4]);
	printf("BMC Staging Region Offset : 0x%08x\n", *(uint32_t *)&read_buf[8]);

	// Read PCH Offset
	if (readUfmProvFifoCmd(args, MB_UFM_PROV_RD_PCH_OFFSETS, read_buf, 12)) {
		printf("Read UFM PCH offset failed\n");
		return 1;
	}
	printf("PCH Active PFM Offset : 0x%08x\n", *(uint32_t *)&read_buf[0]);
	printf("PCH Recovery Region Offset : 0x%08x\n", *(uint32_t *)&read_buf[4]);
	printf("PCH Staging Region Offset : 0x%08x\n", *(uint32_t *)&read_buf[8]);

	// Read Root Key hash
	if (readUfmProvFifoCmd(args, MB_UFM_PROV_RD_ROOT_KEY, read_buf, SHA384_LENGTH)) {
		printf("Read UFM root key hash failed\n");
		return 1;
	}
	printf("Root Key Hash:\n");
	printRawData(read_buf, SHA384_LENGTH);

	return 0;
}

int doProvision(ARGUMENTS args)
{
	uint8_t write_buffer[64];
	int hashLen = 0;

	if (args.lms_mode) {
		HashAlg type;

		type = (args.lms_mode == 384)?Sha384:Sha256;
		if (getLMSRootKeyHash(args.provision_cmd, type, write_buffer, &hashLen)) {
			printf("Get root key hash failed\n");
			return 1;
		}
	} else {
		if (getRootKeyHash(args.provision_cmd, write_buffer, &hashLen)) {
			printf("Get root key hash failed\n");
			return 1;
		}
	}

	if (args.debug_flag) {
		printf("Root key hash\n");
		printRawData(write_buffer, hashLen);
	}

	// Write BMC, PCH region offset
	if (writeUfmProvBmcPchRegionOffset(args)) {
		printf("Write UFM BMC/PCH offset failed\n");
		return 1;
	}

	// Write Root Key hash
	if (writeUfmProvFifoCmd(args, MB_UFM_PROV_ROOT_KEY, write_buffer, hashLen)) {
		printf("Write UFM root key failed\n");
		return 1;
	}

	printf("%s success\n", __func__);
	return 0;
}

int provision(ARGUMENTS args)
{
	FILE *file = NULL;

	if (strcmp(args.provision_cmd, "show") == 0)
		return provisionShow(args);
	else if (strcmp(args.provision_cmd, "lock") == 0)
		return provisionLock(args);
	else {
		file = fopen(args.provision_cmd, "r");

		if (file == NULL) {
			printf("input root key: %s does not exist\n", args.provision_cmd);
			return 1;
		} else {
			printf("input root key: %s\n", args.provision_cmd);
			fclose(file);
		}

		return doProvision(args);
	}
}

int unprovision(ARGUMENTS args)
{
	i2cWriteByteData(args, MB_PROVISION_CMD, MB_UFM_PROV_ERASE);
	i2cWriteByteData(args, MB_UFM_CMD_TRIGGER, MB_UFM_CMD_EXECUTE_MASK);
	if (waitUntilUfmCmdTriggerExec(args) || waitUntilUfmProvStatusCmdDone(args)) {
		printf("%s failed\n", __func__);
		return 1;
	}

	printf("%s success\n", __func__);
	return 0;
}

