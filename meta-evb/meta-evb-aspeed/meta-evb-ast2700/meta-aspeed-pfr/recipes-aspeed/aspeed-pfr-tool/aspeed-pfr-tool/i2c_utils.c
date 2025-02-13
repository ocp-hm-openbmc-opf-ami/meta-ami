/*
 * Copyright (c) 2022 ASPEED Technology Inc.
 *
 * SPDX-License-Identifier: MIT
 */

#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <errno.h>
#include <i2c/smbus.h>
#include <linux/i2c-dev.h>
#include <sys/ioctl.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>
#include "arguments.h"

void printRawData(uint8_t *buf, int len)
{
	int i = 0;

	for (i = 0; i < len; ++i) {
		printf("%02x ", buf[i]);
		if ((i+1)%16 == 0)
			printf("\n");
	}

	printf("\n");
}

int i2cOpenDev(int bus, int slave_addr)
{
	char filename[20];
	int fd;

	snprintf(filename, 19, "/dev/i2c-%d", bus);
	fd = open(filename, O_RDWR);
	if (fd < 0) {
		printf("Unable to open i2c device.\n");
		exit(EXIT_FAILURE);
	}

	if (ioctl(fd, I2C_SLAVE_FORCE, slave_addr) < 0) {
		printf("Unable to set i2c slave address, %x.\n", slave_addr);
		close(fd);
		exit(EXIT_FAILURE);
	}

	return fd;
}

void i2cWriteByteData(ARGUMENTS args, uint8_t offset, uint8_t value)
{
	int retries = 5;

	while (i2c_smbus_write_byte_data(args.i2c_fd, offset, value) < 0) {
		printf("i2c write byte failed, retrying....%d\n", retries);
		if (!retries--)	{
			printf("i2c_smbus_write_byte_data() failed\n");
			exit(EXIT_FAILURE);
		}
		usleep(10*1000);
	}

	if (args.debug_flag)
		printf("write_reg(%02x, %02x)\n", offset, value);
}

void i2cWriteBlockData(ARGUMENTS args, uint8_t offset, uint8_t length, uint8_t *value)
{
	int retries = 5;

	while (i2c_smbus_write_i2c_block_data(args.i2c_fd, offset, length, value) < 0) {
		printf("i2c write block failed, retrying....%d\n", retries);
		if (!retries--)	{
			printf("i2c_smbus_write_i2c_block_data() failed\n");
			exit(EXIT_FAILURE);
		}
		usleep(10*1000);
	}

	if (args.debug_flag) {
		printf("write_block(rf_addr: %02x)\n", offset);
		printRawData(value, length);
	}
}

uint8_t i2cReadByteData(ARGUMENTS args, uint8_t offset)
{
	int value = i2c_smbus_read_byte_data(args.i2c_fd, offset);
	int retries = 5;

	while (value < 0) {
		printf("i2c_smbus_read_byte_data failed, retrying....%d\n", retries);

		if (!retries--)	{
			printf("i2c_smbus_read_byte_data() failed\n");
			exit(EXIT_FAILURE);
		}
		usleep(10*1000);
		value = i2c_smbus_read_byte_data(args.i2c_fd, offset);
	}

	if (args.debug_flag)
		printf("read_reg(%02x, %02x)\n", offset, (uint8_t)value);

	return (uint8_t)value;
}

int i2cReadBlockData(ARGUMENTS args, uint8_t offset, uint8_t length, uint8_t *value)
{
	int read_length = i2c_smbus_read_i2c_block_data(args.i2c_fd, offset, length, value);
	int retries = 5;

	while (read_length < 0) {
		printf("i2c_smbus_read_i2c_block_data, retrying....%d\n", retries);

		if (!retries--)	{
			printf("i2c_smbus_read_i2c_block_data() failed\n");
			exit(EXIT_FAILURE);
		}
		usleep(10*1000);
		read_length = i2c_smbus_read_i2c_block_data(args.i2c_fd, offset, length, value);
	}

	if (args.debug_flag) {
		printf("read_block(rf_addr: %02x)\n", offset);
		printRawData(value, read_length);
	}

	return read_length;
}
