/*
// Copyright (c) 2017-2022 Intel Corporation
//
// This software and the related documents are Intel copyrighted
// materials, and your use of them is governed by the express license
// under which they were provided to you ("License"). Unless the
// License provides otherwise, you may not use, modify, copy, publish,
// distribute, disclose or transmit this software or the related
// documents without Intel's prior written permission.
//
// This software and the related documents are provided as is, with no
// express or implied warranties, other than those that are expressly
// stated in the License.
*/

#ifndef __LPC_DRV_H__
#define __LPC_DRV_H__

#define LPC_DEV_MAJOR	250
#define LPC_DEV_MINOR	0

/***********************************************************************************/

enum KCS_CMD {
	KCS_SET_ADDR = 0,
	KCS_GET_ADDR,
	KCS_SMS_ATN,
	KCS_FORCE_ABORT,
};

struct kcs_ioctl_data {
	unsigned int  cmd;
	unsigned int  data;
};

#define KCS_IOC_BASE                   'K'
#define KCS_IOC_COMMAND                _IOWR(KCS_IOC_BASE, 1, struct kcs_ioctl_data)

/***********************************************************************************/

enum ACPI_SLP_STATE {
	ACPI_STATE_S12 = 1,
	ACPI_STATE_S3I,
	ACPI_STATE_S45
};

/* SWC & ACPI for SuperIO IOCTL */
enum SIO_CMD {
	SIO_GET_ACPI_STATE = 0,
	SIO_GET_PWRGD_STATUS,
	SIO_GET_ONCTL_STATUS,
	SIO_SET_ONCTL_GPIO,
	SIO_GET_PWRBTN_OVERRIDE,
	SIO_GET_PFAIL_STATUS, /* Start from AC Loss */
	SIO_SET_BMC_SCI_EVENT,
	SIO_SET_BMC_SMI_EVENT,

	SIO_MAX_CMD
};

struct sio_ioctl_data {
	unsigned short sio_cmd;
	unsigned short param;
	unsigned int   data;
};

#define SIO_IOC_BASE            'P'
#define SIO_IOC_COMMAND         _IOWR(SIO_IOC_BASE, 1, struct sio_ioctl_data)

/***********************************************************************************/

#define MAX_MAILBOX_NUM         16

/***********************************************************************************/

#define __ASPEED_ESPI_IOCTL_MAGIC	0xb8

/*
 * The IOCTL-based interface works in the eSPI packet in/out paradigm.
 *
 * Only the virtual wire IOCTL is a special case which does not send
 * or receive an eSPI packet. However, to keep a more consisten use from
 * userspace, we make all of the four channel drivers serve through the
 * IOCTL interface.
 *
 * For the eSPI packet format, refer to
 *   Section 5.1 Cycle Types and Packet Format,
 *   Intel eSPI Interface Base Specification, Rev 1.0, Jan. 2016.
 *
 * For the example user apps using these IOCTL, refer to
 *   https://github.com/AspeedTech-BMC/aspeed_app/tree/master/espi_test
 */


/*
 * Virtual Wire Channel (CH1)
 *  - ASPEED_ESPI_VW_GET_GPIO_VAL
 *      Read the input value of GPIO over the VW channel
 *  - ASPEED_ESPI_VW_PUT_GPIO_VAL
 *      Write the output value of GPIO over the VW channel
 */
#define ASPEED_ESPI_VW_GET_GPIO_VAL	_IOR(__ASPEED_ESPI_IOCTL_MAGIC, \
					     0x10, uint8_t)
#define ASPEED_ESPI_VW_PUT_GPIO_VAL	_IOW(__ASPEED_ESPI_IOCTL_MAGIC, \
					     0x11, uint8_t)

#endif

/***********************************************************************************/
