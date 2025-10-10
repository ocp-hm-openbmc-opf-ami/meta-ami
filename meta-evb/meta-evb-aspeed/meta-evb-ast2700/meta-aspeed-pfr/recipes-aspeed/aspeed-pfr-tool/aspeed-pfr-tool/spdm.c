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
#include "utils.h"

#include <linux/mctp.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <errno.h>
#include <inttypes.h>

#include "spdm.h"

void setSPDMFunction(ARGUMENTS args, int enabled)
{
	if (enabled) {
		WriteByteData(args, 0xb, 0x12);
		printf("SPDM is enabled\n");
	} else {
		WriteByteData(args, 0xb, 0x14);
		printf("SPDM is disabled\n");
	}
	WriteByteData(args, 0xc, 0x1);
}

#ifdef SUPPORT_SECURE_CONNECTION
uint32_t m_session_id;
SOCKET m_mctp_tx;
SOCKET m_server_socket;

int init_socket(ARGUMENTS *args)
{
	int sock;

	sock = socket(AF_MCTP, SOCK_DGRAM, 0);
	if (sock == -1) {
		printf("Failed to create socket\n");
		return -1;
	}

	memset(&my_address, 0, sizeof(struct sockaddr_mctp));
	my_address.smctp_family = AF_MCTP;
	my_address.smctp_network = args->mctp_network;
	my_address.smctp_addr.s_addr = args->mctp_dst;
	my_address.smctp_type = MCTP_MESSAGE_TYPE_SPDM;

	if (bind(sock, (struct sockaddr *)&my_address, sizeof(struct sockaddr_mctp)) < 0) {
		printf("Bind error. error - %s\n", strerror(errno));
		close(sock);
		return -1;
	}

	return sock;
}

int init_secure_socket(ARGUMENTS *args)
{
	int sock;

	sock = socket(AF_MCTP, SOCK_DGRAM, 0);
	if (sock == -1) {
		printf("Failed to create secure socket\n");
		return -1;
	}

	memset(&my_address_secure, 0, sizeof(struct sockaddr_mctp));
	my_address_secure.smctp_family = AF_MCTP;
	my_address_secure.smctp_network = args->mctp_network;
	my_address_secure.smctp_addr.s_addr = args->mctp_dst;
	/* Based on Intel Spec. 814910, the IC bit in the secure vendor-defined
	 * format should be enabled
	 */
	my_address_secure.smctp_type = MCTP_MESSAGE_TYPE_SECURED_MCTP | MCTP_IC_FLAG;

	if (bind(sock, (struct sockaddr *)&my_address_secure, sizeof(struct sockaddr_mctp)) < 0) {
		printf("Bind secure socket error. error - %s\n", strerror(errno));
		close(sock);
		return -1;
	}

	return sock;
}

int build_vendor_msg(vendor_def_msg *msg, opcode op, size_t size, uint8_t *value)
{
	if (msg == NULL) {
		printf("Invalid argument, tx = %p\n", msg);
		return -1;
	}
	memset(msg->data, 0, sizeof(msg->data));
	msg->hdr.msg_hdr.msg_type = VENDOR_DEFINED_MSG_TYPE;
	msg->hdr.msg_hdr.ic = 1;
	msg->hdr.msg_hdr.pcie_vendor_id = PCIE_VENDOR_ID;
	msg->hdr.msg_hdr.rq = 1;
	msg->hdr.msg_hdr.dbit = 0;
	msg->hdr.msg_hdr.rvsd = 0;
	msg->hdr.msg_hdr.instance_id = 0;
	msg->hdr.msg_hdr.msg_opcode = INTEL_MESSAGE_OPCODE;
	msg->hdr.command = op;
	msg->hdr.seq_num = 0;
	msg->hdr.status = 0;
	msg->hdr.address = *value;
	msg->hdr.length = size;

	memcpy(msg->data, value, size);
	return 0;
}

int process_secure_msg(vendor_def_msg *msg, size_t data_size, uint8_t *rsp, size_t *rsp_size)
{
	size_t req_size, message_size;
	libspdm_context_t *spdm_context = m_spdm_context;
	uint8_t *message;
	uint32_t status;
	intel_pfr_doe_header *hdr;
	uint8_t *ptr;

	req_size = sizeof(intel_pfr_doe_header) + data_size;

	status = libspdm_acquire_sender_buffer(spdm_context, &message_size, (void **)&message);
	if (status) {
		printf("Failed to acquire sender buffer (%x)\n", status);
		return -1;
	}
	memcpy(message, (uint8_t *)msg, req_size);

	status = libspdm_send_request(spdm_context, &m_session_id, true, req_size, message);
	if (status) {
		printf("Failed to send request (%x)\n", status);
		libspdm_release_sender_buffer(spdm_context);
		return -1;
	}
	libspdm_release_sender_buffer(spdm_context);

	status = libspdm_acquire_receiver_buffer(spdm_context, &message_size, (void **)&message);
	if (status) {
		printf("Failed to acquire receiver buffer (%x)\n", status);
		return -1;
	}

	status = libspdm_receive_response(spdm_context, &m_session_id, true,
			&message_size, (void **)&message);
	if (status) {
		printf("Failed to rcv request (%x)\n", status);
		return -1;
	}

	if (message_size < sizeof(intel_pfr_doe_header)) {
		printf("Invalid data length (%zu)\n", message_size);
		return -1;
	}

	hdr = (intel_pfr_doe_header *)message;
	message_size -= sizeof(intel_pfr_doe_header);
	ptr = (uint8_t *)(hdr + 1);
	if (message_size > *rsp_size) {
		printf("Get more data than the rsp buffer (%zu, %zu)\n", message_size, *rsp_size);
		message_size = *rsp_size;
	} else {
		*rsp_size = message_size;
	}
	memcpy(rsp, ptr, message_size);

	libspdm_release_receiver_buffer(spdm_context);

	return 0;
}

libspdm_return_t create_session_via_spdm(bool use_psk)
{
	void *spdm_context;
	libspdm_return_t status;
	uint32_t session_id = -1;
	uint8_t heartbeat_period;
	uint8_t measurement_hash[LIBSPDM_MAX_HASH_SIZE];

	spdm_context = m_spdm_context;
	heartbeat_period = HEART_BEAT_PERIOD;
	libspdm_zero_mem(measurement_hash, sizeof(measurement_hash));
	status = libspdm_start_session(spdm_context, use_psk,
					m_use_measurement_summary_hash_type,
					m_use_slot_id, m_session_policy, &session_id,
					&heartbeat_period, measurement_hash);
	if (LIBSPDM_STATUS_IS_ERROR(status)) {
		printf("libspdm_start_session - %x\n", (uint32_t)status);
		return status;
	}
	/* Init session related variables */
	isSessionCreated = true;
	m_socket_org = m_socket;
	m_socket = m_mctp_secure;
	m_session_id = session_id;

	return status;
}

int close_secure_session(ARGUMENTS *args)
{
	uint32_t status;

	status = libspdm_stop_session(m_spdm_context, m_session_id, 1);
	if (LIBSPDM_STATUS_IS_ERROR(status))
		printf("libspdm_stop_session - %x\n", (uint32_t)status);

	m_session_id = 0;
	m_socket = m_socket_org;
	isSessionCreated = false;
	return 0;
}

int setupSecureConnect(ARGUMENTS *args)
{
	void *spdm_context = NULL;
	uint32_t status;

	m_socket = init_socket(args);
	if (m_socket == -1) {
		fprintf(stderr, "Failed to create socket\n");
		return -1;
	}

	m_mctp_secure = init_secure_socket(args);
	if (m_mctp_secure == -1) {
		fprintf(stderr, "Failed to create socket\n");
		return -1;
	}
	m_mctp_medium = 0;
	m_use_transport_layer = SOCKET_TRANSPORT_TYPE_NONE;

	/* Init global settings for libspdm */
	if (args->debug_flag)
		debug_level = LIBSPDM_DEBUG_INFO | LIBSPDM_DEBUG_VERBOSE|
				LIBSPDM_DEBUG_ERROR | LIBSPDM_DEBUG_FILE;
	else
		debug_level = 0;

	m_use_measurement_operation = 0;
	spdm_mode = SPDM_REQUESTER_MODE;
	m_support_req_asym_algo = SPDM_ALGORITHMS_BASE_ASYM_ALGO_TPM_ALG_ECDSA_ECC_NIST_P384;
	m_use_requester_capability_flags = SPDM_GET_CAPABILITIES_REQUEST_FLAGS_CERT_CAP |
		SPDM_GET_CAPABILITIES_REQUEST_FLAGS_CHAL_CAP |
		SPDM_GET_CAPABILITIES_REQUEST_FLAGS_MAC_CAP |
		SPDM_GET_CAPABILITIES_REQUEST_FLAGS_ENCRYPT_CAP |
		SPDM_GET_CAPABILITIES_REQUEST_FLAGS_MUT_AUTH_CAP |
		SPDM_GET_CAPABILITIES_REQUEST_FLAGS_KEY_EX_CAP |
		SPDM_GET_CAPABILITIES_REQUEST_FLAGS_ENCAP_CAP |
		SPDM_GET_CAPABILITIES_REQUEST_FLAGS_HBEAT_CAP |
		SPDM_GET_CAPABILITIES_REQUEST_FLAGS_KEY_UPD_CAP |
		SPDM_GET_CAPABILITIES_REQUEST_FLAGS_HANDSHAKE_IN_THE_CLEAR_CAP;
	m_use_version = 0x12;

	if (chdir("/usr/share/spdm-emu/")) {
		fprintf(stderr, "Failed to switch to /usr/share/spdm-emu/\n");
		return -1;
	}

	// Init spdm context
	spdm_context = spdm_client_init();
	if (spdm_context == NULL) {
		close(m_socket);
		close(m_mctp_secure);
		fprintf(stderr, "Failed to init spdm context\n");
		return -1;
	}

	// Run SPDM basic commands (get version, get capabilities, get algorithm)
	status = do_authentication_via_spdm();
	if (status) {
		close(m_socket);
		close(m_mctp_secure);
		fprintf(stderr, "do_authentication_via_spdm status = %x\n", status);
		return -1;
	}

	// Create session with key exchange command
	status = create_session_via_spdm(false);
	if (status) {
		close(m_socket);
		close(m_mctp_secure);
		fprintf(stderr, "create_session_via_spdm status = %x\n", status);
		return -1;
	}

	return 0;
}

int mctp_message_tx(void *mctp, mctp_eid_t eid, void *msg, size_t len,
			bool tag_owner, uint8_t tag, void *msg_binding_private)
{
	/* This dummy function is used to fix compiler error */
	return 0;
}

#ifdef SECURE_TEST_CASE
#include <time.h>
#define SEC_TO_MS(sec) ((sec)*1000)
#define NS_TO_MS(ns)    ((ns)/1000000)

uint64_t get_diff_ms(struct timespec *old, struct timespec *new)
{
	uint64_t old_ms = SEC_TO_MS((uint64_t)old->tv_sec) + NS_TO_MS((uint64_t)old->tv_nsec);
	uint64_t new_ms = SEC_TO_MS((uint64_t)new->tv_sec) + NS_TO_MS((uint64_t)new->tv_nsec);

	return new_ms - old_ms;
}
void test_case_handler(ARGUMENTS *args, int test_case_id, bool close_session)
{
	uint32_t status, i, random_sleep;
	uint32_t loop_count = 10000;
	uint8_t addr, curr_value, new_value, value;

	switch (test_case_id) {
	case 1:
		printf("Case 1: %d heartbeat test\n", loop_count);
		for (i = 0; i < loop_count; i++) {
			status = libspdm_heartbeat(m_spdm_context, m_session_id);
			if (status)
				break;
		}
		printf("Case 1 is %s, status = %x\n", (status)?"failed":"passed", status);
		break;
	case 2:
		printf("Case 2: send random heartbeat test\n");
		srand(time(NULL));
		for (i = 0; i < loop_count; i++) {
			status = libspdm_heartbeat(m_spdm_context, m_session_id);
			if (status)
				break;
			// Random sleep 1 ~ HEART_BEAT_PERIOD-1 seconds
			random_sleep = (rand()%(HEART_BEAT_PERIOD - 1)) + 1;
			sleep(random_sleep);
		}
		printf("Case 2 is %s, status = %x\n", (status)?"failed":"passed", status);
		break;
	case 3:
		printf("Case 3: key update test\n");
		for (i = 0; i < loop_count; i++) {
			status = libspdm_key_update(m_spdm_context, m_session_id, false);
			if (status) {
				printf("key update failed\n");
				break;
			}
			// After key is updated, to send a heartbeat to confirm new key status
			status = libspdm_heartbeat(m_spdm_context, m_session_id);
			if (status)
				break;
		}
		printf("Case 3 is %s, status = %x\n", (status)?"failed":"passed", status);
		break;
	case 4:
		printf("Case 4: negative test, heart beat is sent over expected value\n");
		sleep(HEART_BEAT_PERIOD * 3);
		status = libspdm_heartbeat(m_spdm_context, m_session_id);
		printf("Case 4 is %s\n", (status)?"passed":"failed");
		close_secure_session(args);
		/*
		 * The previous session will be expired due to timeout,
		 * to create a new session for other test case
		 */
		status = libspdm_init_connection(m_spdm_context,
				(m_exe_connection & EXE_CONNECTION_VERSION_ONLY) != 0);
		if (status) {
			close(m_socket);
			close(m_mctp_secure);
			fprintf(stderr, "libspdm_init_connection status = %x\n", status);
			break;
		}

		status = do_authentication_via_spdm();
		if (status) {
			close(m_socket);
			close(m_mctp_secure);
			fprintf(stderr, "do_authentication_via_spdm status = %x\n", status);
			break;
		}

		// Create session with key exchange command
		status = create_session_via_spdm(false);
		if (status) {
			close(m_socket);
			close(m_mctp_secure);
			fprintf(stderr, "create_session_via_spdm status = %x\n", status);
			break;
		}
		break;
	case 5:
		printf("Case 5: host mailbox command - write test\n");
		addr = 0x63; //SMBus Ownership
		curr_value = ReadByteData(*args, addr);
		for (i = 0; i < loop_count; i++) {
			if (curr_value & 0x1)
				new_value = curr_value & 0xfe;
			else
				new_value = curr_value | 1;

			WriteByteData(*args, addr, new_value);
			value = ReadByteData(*args, addr);
			if (new_value != value) {
				printf("Write value %x to addr %x is failed\n", new_value, addr);
				break;
			}
			// Restore original value
			WriteByteData(*args, addr, curr_value);
		}
		printf("Case 5 is passed\n");
		break;
	case 6:
	{
		struct timespec tv1, tv2, tv3, tv4, tv5;
		uint64_t time_diff1, time_diff2, time_diff3, time_diff4;

		// Close previous session and create a new session for measuring performance data
		close_secure_session(args);
		printf("Start to measure time consumption with secure connection\n");
		timespec_get(&tv1, TIME_UTC);
		status = libspdm_init_connection(m_spdm_context,
				(m_exe_connection & EXE_CONNECTION_VERSION_ONLY) != 0);
		if (status) {
			close(m_socket);
			close(m_mctp_secure);
			fprintf(stderr, "libspdm_init_connection status = %x\n", status);
			break;
		}

		status = do_authentication_via_spdm();
		if (status) {
			close(m_socket);
			close(m_mctp_secure);
			fprintf(stderr, "do_authentication_via_spdm status = %x\n", status);
			break;
		}

		// Create session with key exchange command
		status = create_session_via_spdm(false);
		if (status) {
			close(m_socket);
			close(m_mctp_secure);
			fprintf(stderr, "create_session_via_spdm status = %x\n", status);
			break;
		}
		timespec_get(&tv2, TIME_UTC);
		for (i = 0; i < 10; i++)
			value = ReadByteData(*args, 0x60);

		timespec_get(&tv3, TIME_UTC);
		for (i = 0; i < 100; i++)
			value = ReadByteData(*args, 0x60);

		timespec_get(&tv4, TIME_UTC);
		for (i = 0; i < 1000; i++)
			value = ReadByteData(*args, 0x60);

		timespec_get(&tv5, TIME_UTC);

		time_diff1 = get_diff_ms(&tv1, &tv2);
		time_diff2 = get_diff_ms(&tv2, &tv3);
		time_diff3 = get_diff_ms(&tv3, &tv4);
		time_diff4 = get_diff_ms(&tv4, &tv5);

		printf("session creation : %" PRId64 " ms\n", time_diff1);
		printf("10   rounds read : %" PRId64 " ms\n", time_diff2);
		printf("100  rounds read : %" PRId64 " ms\n", time_diff3);
		printf("1000 rounds read : %" PRId64 " ms\n", time_diff4);
		break;
	}
	case 7:
	{
		struct timespec tv2, tv3, tv4, tv5;
		uint64_t time_diff2, time_diff3, time_diff4;

		printf("Start to measure time consumption without secure connection\n");
		args->secure_mode = 0;
		args->i2c_fd = i2cOpenDev(args->i2c_bus, args->rot_addr);
		timespec_get(&tv2, TIME_UTC);
		for (i = 0; i < 10; i++)
			value = ReadByteData(*args, 0x60);

		timespec_get(&tv3, TIME_UTC);
		for (i = 0; i < 100; i++)
			value = ReadByteData(*args, 0x60);

		timespec_get(&tv4, TIME_UTC);
		for (i = 0; i < 1000; i++)
			value = ReadByteData(*args, 0x60);

		timespec_get(&tv5, TIME_UTC);

		time_diff2 = get_diff_ms(&tv2, &tv3);
		time_diff3 = get_diff_ms(&tv3, &tv4);
		time_diff4 = get_diff_ms(&tv4, &tv5);

		printf("10   rounds read : %" PRId64 " ms\n", time_diff2);
		printf("100  rounds read : %" PRId64 " ms\n", time_diff3);
		printf("1000 rounds read : %" PRId64 " ms\n", time_diff4);
		args->secure_mode = 1;
	}
	default:
		break;
	}
	if (close_session)
		close_secure_session(args);
}
#endif
#else
int build_vendor_msg(vendor_def_msg *msg, opcode op, size_t size, uint8_t *value)
{
	// do nothing
	return 0;
}

int process_secure_msg(vendor_def_msg *msg, size_t data_size, uint8_t *rsp, size_t *rsp_size)
{
	// do nothing
	return 0;
}

void test_case_handler(ARGUMENTS *args, int test_case_id, bool close_session)
{
	// do nothing
}

int close_secure_session(ARGUMENTS *args)
{
	// do nothing
	return 0;
}
#endif // #ifdef SUPPORT_SECURE_CONNECTION
