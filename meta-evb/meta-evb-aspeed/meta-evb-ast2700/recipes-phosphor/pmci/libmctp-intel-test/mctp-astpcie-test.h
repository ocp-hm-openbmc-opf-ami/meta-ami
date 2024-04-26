/* SPDX-License-Identifier: Apache-2.0 OR GPL-2.0-or-later */
/*
 * Copyright 2021-2022 Aspeed Technology Inc.
 */
#ifndef _MCTP_ASTPCIE_TEST_H_
#define _MCTP_ASTPCIE_TEST_H_

#ifdef __cplusplus
extern "C" {
#endif

#include <libmctp-astpcie.h>

/* Test MCTP ctx */
struct test_mctp_ctx {
	struct mctp_binding *astpcie_binding;
	struct mctp *mctp;
	uint16_t len;
	void *rx_buf;
	void *port;
};

struct mctp_binding_astpcie {
	struct mctp_binding binding;
	uint16_t bdf;
	uint8_t medium_id;
	int fd;
};

void usage(FILE *fp, int argc, char **argv);
void rx_response_handler(uint8_t eid, void *data, void *msg, size_t len,
			 bool tag_owner, uint8_t tag, void *prv);
void rx_request_handler(mctp_eid_t src, void *data, void *msg, size_t len,
			bool tag_owner, uint8_t tag, void *msg_binding_private);
void rx_request_control_handler(mctp_eid_t src, void *data, void *msg, size_t len,
				bool tag_owner, uint8_t tag, void *msg_binding_private);
void wait_for_request(struct test_mctp_ctx *ctx);
int test_mctp_astpcie_recv_data_timeout_raw(struct test_mctp_ctx *ctx, uint8_t dst, int TOsec);
struct test_mctp_ctx *test_mctp_astpcie_init(char *mctp_dev, uint8_t bus, uint8_t routing, uint8_t dst_dev, uint8_t dst_func,
					     uint8_t dst_eid, uint8_t src_eid);
int test_mctp_astpcie_send_data(struct test_mctp_ctx *ctx, uint8_t dst, uint8_t flag_tag,
				void *req, size_t size);
void test_mctp_astpcie_free(struct test_mctp_ctx *ctx);
int test_send_mctp_cmd(char *mctp_dev, uint8_t bus, uint8_t routing, uint8_t dst_dev, uint8_t dst_func, uint8_t dst_eid, uint8_t src_eid,
		       uint8_t *tbuf, int tlen, uint8_t *rbuf, int *rlen);
int test_mctp_astpcie_get_bdf(char *mctp_dev, uint8_t *src_bus, uint8_t *src_dev, uint8_t *src_func);
struct test_mctp_ctx *test_mctp_astpcie_init(char *mctp_dev, uint8_t bus, uint8_t routing, uint8_t dst_dev, uint8_t dst_func,
					     uint8_t dst_eid, uint8_t src_eid);
int test_mctp_fake_responder(char *mctp_dev, uint8_t bus, uint8_t routing, uint8_t dst_dev, uint8_t dst_func,
			     uint8_t dst_eid, uint8_t src_eid);

#ifdef __cplusplus
} /* extern "C" */
#endif

#endif /* _MCTP_ASTPCIE_TEST_H_ */
