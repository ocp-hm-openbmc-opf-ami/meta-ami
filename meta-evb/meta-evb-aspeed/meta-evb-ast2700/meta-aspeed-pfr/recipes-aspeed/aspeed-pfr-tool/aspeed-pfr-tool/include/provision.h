/*
 * Copyright (c) 2022 ASPEED Technology Inc.
 *
 * SPDX-License-Identifier: MIT
 */

#pragma once
#include <stdint.h>
#include "arguments.h"

#define SHA256_LENGTH 32
#define SHA384_LENGTH 48
#define SHA512_LENGTH 64

// Supported Hash Algorithms
typedef enum {
	Sha256,
	Sha384,
	Sha512
} HashAlg;

int provision(ARGUMENTS args);
int unprovision(ARGUMENTS args);

