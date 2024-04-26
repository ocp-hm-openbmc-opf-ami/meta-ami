/* SPDX-License-Identifier: Apache-2.0 OR GPL-2.0-or-later */
/*
 * Copyright 2021-2022 Aspeed Technology Inc.
 */
#include <stdio.h>
#include <stdint.h>
#include <string.h>
#include "mctp-test-utils.h"

void print_raw_data(uint8_t *buf, int len)
{
	int i = 0;

	for (i = 0; i < len; ++i)
		printf("%02x ", buf[i]);

	printf("\n");
}

void test_pattern_prepare(uint8_t *pattern, int size)
{
	int i;
	int j;

	for (i = 0; i < size; i++) {
		j = i % 0x100;
		pattern[i] = j;
	}
}

int verify_mctp_echo_cmd(uint8_t *tbuf, int tlen, uint8_t *rbuf, int rlen)
{
	int hdr_completion_len = sizeof(struct mctp_ctrl_msg_hdr) + 1;
	struct mctp_ctrl_msg_hdr expected_resp_hdr;
	struct mctp_echo_resp *resp;
	struct mctp_ctrl_req *req;

	if (tlen < sizeof(struct mctp_ctrl_msg_hdr)) {
		printf("verify request length failed...expected(%zd), req(%d)\n",
			sizeof(struct mctp_ctrl_msg_hdr), tlen);
		goto dump_msg;
	}

	// response data add 1 byte complition code
	if (rlen < hdr_completion_len) {
		printf("verify response length failed...expected(%d), resp(%d)\n",
			hdr_completion_len, rlen);
		goto dump_msg;
	}

	resp = (struct mctp_echo_resp *)rbuf;
	req = (struct mctp_ctrl_req *)tbuf;

	// request message type
	if (req->hdr.ic_msg_type != MCTP_MESSAGE_TYPE_ASPEED_ECHO_TEST) {
		printf("verify request message type failed...expected(0x%02x), req(0x%02x)\n",
			MCTP_MESSAGE_TYPE_ASPEED_ECHO_TEST, req->hdr.ic_msg_type);
		goto dump_msg;
	}

	if ((tlen + 1) != rlen) {
		printf("verify response length failed...expected(%d), resp(%d)\n",
			tlen + 1, rlen);
		goto dump_msg;
	}

	memcpy(&expected_resp_hdr, req, sizeof(expected_resp_hdr));
	expected_resp_hdr.rq_dgram_inst &= 0x7f;

	// response header
	if (memcmp(&expected_resp_hdr, &resp->hdr, sizeof(expected_resp_hdr))) {
		printf("verify response header failed...\n");
		printf("expected header:\n");
		print_raw_data((uint8_t *)&expected_resp_hdr, sizeof(expected_resp_hdr));
		printf("response header:\n");
		print_raw_data((uint8_t *)&resp->hdr, sizeof(expected_resp_hdr));
		goto dump_msg;
	}

	// complition code
	if (resp->completion_code != MCTP_CTRL_CC_SUCCESS) {
		printf("verify response completion code failed...expected(%d), resp(%d)\n",
			MCTP_CTRL_CC_SUCCESS, resp->completion_code);
		goto dump_msg;
	}

	// payload data
	if (rlen > hdr_completion_len) {
		if (memcmp(req->data, resp->data, (rlen - hdr_completion_len))) {
			printf("verify response payload failed...\n");
			printf("expected payload:\n");
			print_raw_data(req->data, (rlen - hdr_completion_len));
			printf("response payload:\n");
			print_raw_data(resp->data, (rlen - hdr_completion_len));
			goto dump_msg;
		}
	}

	printf("pass\n");
	return 0;

dump_msg:
	printf("request data:\n");
	print_raw_data(tbuf, tlen);
	printf("response data:\n");
	print_raw_data(rbuf, rlen);
	printf("failed\n");
	return -1;
}

