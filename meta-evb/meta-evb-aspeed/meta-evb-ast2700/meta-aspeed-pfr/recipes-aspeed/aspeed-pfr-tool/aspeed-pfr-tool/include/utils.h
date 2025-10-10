/*
 * Copyright (c) 2024 ASPEED Technology Inc.
 *
 * SPDX-License-Identifier: MIT
 */

#pragma once
#include "arguments.h"

void WriteByteData(ARGUMENTS args, uint8_t offset, uint8_t value);
void WriteBlockData(ARGUMENTS args, uint8_t offset, uint8_t length, uint8_t *value);
uint8_t ReadByteData(ARGUMENTS args, uint8_t offset);
int ReadBlockData(ARGUMENTS args, uint8_t offset, uint8_t length, uint8_t *value);
