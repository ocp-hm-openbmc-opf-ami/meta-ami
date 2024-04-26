/* SPDX-License-Identifier: Apache-2.0 OR GPL-2.0-or-later */
/*
 * Copyright 2021-2022 Aspeed Technology Inc.
 */
#ifndef _MCTP_TEST_UTILS_H_
#define _MCTP_TEST_UTILS_H_

#ifdef __cplusplus
extern "C" {
#endif

#include <libmctp.h>
#include <libmctp-log.h>
#include <libmctp-cmds.h>

#define MCTP_MESSAGE_TYPE_ASPEED_ECHO_TEST 0x7c
#define MCTP_ASPEED_CTRL_CMD_ECHO 0x00
#define MCTP_ASPEED_CTRL_CMD_ECHO_LARGE 0x01
#define TEST_BUFF_SIZE 2048
#define TEST_TX_BUFF_SIZE (TEST_BUFF_SIZE + sizeof(struct mctp_ctrl_msg_hdr))
#define TEST_RX_BUFF_SIZE (TEST_BUFF_SIZE + sizeof(struct mctp_ctrl_msg_hdr) + 1)

#define REQUESTER_EID 8
#define RESPONDER_EID 9

struct mctp_ctrl_req {
	struct mctp_ctrl_msg_hdr hdr;
	uint8_t data[MCTP_BTU];
};

struct mctp_ctrl_resp {
	struct mctp_ctrl_msg_hdr hdr;
	uint8_t completion_code;
	uint8_t data[MCTP_BTU];
};

struct mctp_echo_resp {
	struct mctp_ctrl_msg_hdr hdr;
	uint8_t completion_code;
	uint8_t data[TEST_BUFF_SIZE];
};

void print_raw_data(uint8_t *buf, int len);
void test_pattern_prepare(uint8_t *pattern, int size);
int verify_mctp_echo_cmd(uint8_t *tbuf, int tlen, uint8_t *rbuf, int rlen);

#ifdef __cplusplus
} /* extern "C" */
#endif

#endif /* _MCTP_TEST_UTILS_H_ */
