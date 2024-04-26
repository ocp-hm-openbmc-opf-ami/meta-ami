# References
- Management Component Transport Protocol (MCTP) SMBus/I2C Transport Binding Specification
  - https://www.dmtf.org/sites/default/files/standards/documents/DSP0237_1.2.0.pdf
- IPMI - Intelligent Platform Management Bus Communications Protocol Specification v1.0
  - https://www.intel.com/content/dam/www/public/us/en/documents/product-briefs/ipmp-spec-v1.0.pdf
- Management Component Transport Protocol (MCTP) Base Specification Includes MCTP Control Specifications
  - https://www.dmtf.org/sites/default/files/standards/documents/DSP0236_1.3.1.pdf
- Management Component Transport Protocol (MCTP) PCIe VDM Transport Binding Specification
  - https://www.dmtf.org/sites/default/files/standards/documents/DSP0238_1.2.0.pdf
- Facebook OpenBMC
  - https://github.com/facebook/openbmc/tree/helium/common/recipes-lib/mctp
  - https://github.com/facebook/openbmc/tree/helium/common/recipes-lib/obmc-mctp
  - https://github.com/facebook/openbmc/tree/helium/common/recipes-core/mctp-util
- Intel-BMC/libmctp
  - https://github.com/Intel-BMC/libmctp
- Intel-BMC/pmci
  - https://github.com/Intel-BMC/pmci
- Intel-BMC/linux
  - https://github.com/Intel-BMC/linux
- OpenBMC/libmctp
  - https://github.com/openbmc/libmctp

# Dependencies
- It is required to use Intel-BMC/libmctp to build this test program. The reason are as following.
  - Intel-BMC/libmctp has not been upstreamed to OpenBMC/libmctp, yet.
  - OpenBMC/libmctp only supports linux kernel v5.15 and higher version. To fix conflict issue between Intel-BMC/libmctp and OpenBMC/libmctp, Intel-BMC/libmctp is only used
to build this test program. It will not install header files and static library of Intel-BMC/libmctp into image.

# MCTP Message Type
## MCTP control messages (0x00)
So far, this test program only supports **Get Message Type Support** command.
### Supported command
- Get Message Type Support (0x05)

User should get the success completion code, 0x00 and MCTP Message Type count, 0x05

```
0x00 0x05
```

- Other command

User should get the unsupported command completion code, 0x05

```
0x05
```

## ASPEED echo messages type (0x7c)
To test loopback mode for the request data, creates a new MCTP message type.
### Supported command
- ECHO (0x00)

User should get the success completion code, 0x00 and request payload data.

ex: request payload data is : 0x01 0x02 0x03 0x04 0x05

The response data should be one success completion code with request payload data.

```
0x00 0x01 0x02 0x03 0x04 0x05
```

- ECHO_LARGE (0x01)

This command the same as ECHO command but users can use **-l** option to automatically create long request data.

ex: **-l 16**, the request payload data will be 0x00 0x01 0x02 0x03 0x04 0x05 0x06 0x07 0x08 0x09 0x0a 0x0b 0x0c 0x0d 0x0e 0x0f

The response data should be one success completion code with request payload data.

```
0x00 0x00 0x01 0x02 0x03 0x04 0x05 0x06 0x07 0x08 0x09 0x0a 0x0b 0x0c 0x0d 0x0e 0x0f
```

- Other command

User should get the unsupported command completion code, 0x05

```
0x05
```

# MCTP over PCIE
##  MCTP over PCI Express VDM transport
The transferring MCTP packets between endpoints on PCI Express™ using PCIe Vendor Defined Messages (VDMs)
A MCTP over PCIe VDM compliant PCIe device shall support MCTP over PCIe VDM communications on at least one PCIe Physical Function (PF) of the device. If a MCTP over PCIe VDM compliant PCI device supports MCTP over PCIe VDM communications on more than one PCIe function, then MCTP over PCIe VDM communication on each function shall be independent from MCTP over PCIe VDM communications on other PCIe functions.
##  Packet format
The MCTP over PCI Express (PCIe) VDM transport binding transfers MCTP messages using PCIe Type 1 VDMs with data. MCTP messages use the MCTP VDM code value (0000b) that uniquely differentiates MCTP messages from other DMTF VDMs. The fields labeled “PCIe Medium-Specific Header” and “PCIe Medium-Specific Trailer” are specific to carrying MCTP packets using PCIe VDMs. The fields labeled “MCTP Transport Header” and “MCTP Packet Payload” are common fields for all MCTP packets and messages and are specified in MCTP. The location of those fields when they are carried in a PCIe VDM. The PCIe specification allows the last four bytes of the PCIE VDM header to be vendor defined. The MCTP over PCIe VDM transport binding specification uses these bytes for MCTP Transport header fields under the DMTF Vendor ID. This document also specifies the medium-specific use of the MCTP “Hdr Version” field.

## Test
**It is required to get the BDF information if users test route by ID and two EVB role are endpoints.**

### Usage
```
Usage: mctp-astpcie-test [options] <bus_num> <routing_type> <dst_dev> <des_func> <dst_eid> <src_eid> <message_type> <cmd payload>

Sends MCTP data over PCIE
Options:
 -h | --help           print this message
 -t | --req            requester
 -r | --resp           responder
 -d | --deb            debug
 -l | --len            data length
 -c | --count          test times
 -g | --gbdf           get BDF information
 -n | --noresp         no response
 -o | --node           mctp device node(defalut: /dev/aspeed-mctp)
 -v | --verify_echo    verify echo command
Command fields
 <bus_num>         destination PCIE bus number
 <routing_type>    PCIE routing type 0: route to RC, 2: route by ID, 3: Broadcast from RC
 <dst_dev>         destination PCIE device number
 <dst_func>        destination PCIE function number
 <dst_eid>         destination EID
 <src_eid>         source EID
 <type>            MCTP message type
   0x00                - MCTP Control Message
   0x7c                - ASPEED Echo Message
 example: get BDF: mctp-astpcie-test -g
 example: rx : mctp-astpcie-test -r 2 2 0 0 8 9
 example: tx :
   MCTP Control Message
       GET MESSAGE TYPE SUPPORT : mctp-astpcie-test -t 10 2 0 0 9 8 0x00 0x80 0x05
   MCTP ASPEED Echo Message
       ECHO : mctp-astpcie-test -t 10 2 0 0 9 8 0x7c 0x80 0x00 0x01 0x02 0x03 0x04 0x05
       ECHO LARGE: mctp-astpcie-test -t -l 32 10 2 0 0 9 8 0x7c 0x80 0x01
```

### Get PCIE BDF
- mctp-astpcie-test -g

The response data is:

```
src_bus=9, src_dev=0, src_func=0
```

It shows that bus number is 9, device id is 0 and function id is 0.

### Responder (EVB A)
- bus number 10
- route by ID 2
- device 0
- function 0
- eid 9

Step 1: Create a fake responder
- mctp-astpcie-test -r 2 2 0 0 8 9

The response data is:

The fake responder should be created successfully and waiting for request data.

### Requester (EVB B)
- bus number 2
- route by ID 2
- device 0
- function 0
- eid 8

Step 1: Send MCTP control message (0x00) with Get Message Type Support command (0x05)
- mctp-astpcie-test -t 10 2 0 0 9 8 0x00 0x80 0x05

The response data is:

```
00 00 05 00 05
```

Step 2: Send MCTP control message (0x00) with Get Endpoint ID command (0x02)
- mctp-astpcie-test -t 10 2 0 0 9 8 0x00 0x80 0x02

The response data is:

```
00 00 02 05
```

Step 3: Send ASPEED echo message type (0x7c) with ECHO command (0x00)
- mctp-astpcie-test -t 10 2 0 0 9 8 0x7c 0x80 0x00 0x01 0x02 0x03 0x04 0x05

The response data is:

```
7c 00 00 00 01 02 03 04 05
```

Step 4: Send ASPEED echo message type (0x7c) with ECHO_LARGE command (0x01)
- mctp-astpcie-test -t -l 32 10 2 0 0 9 8 0x7c 0x80 0x01

The response data is:

```
7c 00 01 00 00 01 02 03 04 05 06 07 08 09 0a 0b 0c 0d 0e 0f 10 11 12 13 14 15 16 17 18 19 1a 1b 1c 1d 1e 1f
```

Step 5: Send ASPEED echo message type (0x7c) with unsupported command (0x03)
- mctp-astpcie-test -t 10 2 0 0 9 8 0x7c 0x80 0x03 (Note, it should use 8-bits slave address)

The response data is:

```
7c 00 03 05
```

# MCTP over SMBUS
## MCTP packet encapsulation
All MCTP transactions are based on the SMBus Block Write bus protocol. The first 8 bytes make up the packet header. The first three fields—Destination Slave Address, Command Code, and Length—map directly to SMBus functional fields. The remaining header and payload fields map to SMBus Block Write "Data Byte" fields.

## Request / Response Protocol
The MCTP uses a Request / Response protocol the same as IPMB. A Request Message is issued to an intelligent device. The device responds with a separate Response Message. Both Request Messages and Response Messages are transmitted on the bus using **I2C Master Write transfers**. That is, a Request Message is issued from an intelligent device acting as an I2C master, and is received by an Intelligent Device as an I2C slave. The corresponding Response Message is issued from the responding intelligent device as an I2C master, and is received by the request originator as an I2C slave.

## Test
**It is required to add a slave-mqueue device to receive data as an I2C slave.**
- Add slave-mquue device at bus 8 with slave address 0x12
  - echo slave-mqueue 0x12 > /sys/bus/i2c/devices/i2c-8/new_device
- Delete slave-mquesue device from bus 8 with slave address 0x12
  - echo 0x12 > /sys/bus/i2c/devices/i2c-8/delete_device

### Usage
```
Usage: mctp-smbus-test [options] <bus_num> <dst_addr> <src_addr> <dst_eid> <src_eid> <message_type> <cmd payload>

Sends MCTP data over SMbus
Options:
 -h | --help           print this message
 -t | --req            requester
 -r | --resp           responder
 -d | --deb            debug
 -l | --len            data length
 -c | --count          test times
 -n | --noresp         no response
 -v | --verify_echo    verify echo command
Command fields
 <bus_num>         I2C bus number
 <dst_addr>        destination slave address
 <src_addr>        source slave address
 <dst_eid>         destination EID
 <src_eid>         source EID
 <type>            MCTP message type
   0x00                - MCTP Control Message
   0x7c                - ASPEED Echo Message
 example: rx : mctp-smbus-test -r 8 0x24 0x28 8 9
 example: tx :
   MCTP Control Message
       GET MESSAGE TYPE SUPPORT : mctp-smbus-test -t 8 0x28 0x24 9 8 0x00 0x80 0x05
   MCTP ASPEED Echo Message
       ECHO : mctp-smbus-test -t 8 0x28 0x24 9 8 0x7c 0x80 0x00 0x01 0x02 0x03 0x04 0x05
       ECHO LARGE: mctp-smbus-test -t -l 32 8 0x28 0x24 9 8 0x7c 0x80 0x01
```

### Responder (EVB A)
- bus number 8
- slave address 0x14(7-bits) -> 0x28(8-bits)
- eid 9

Step 1: Create a slave-mqueue device
- echo slave-mqueue 0x14 >  /sys/bus/i2c/devices/i2c-8/new_device (Note, it should use 7-bits slave address)
- ls /sys/bus/i2c/devices/i2c-8/8-0014/slave-mqueue

The response data is:
```
/sys/bus/i2c/devices/i2c-8/8-0014/slave-mqueue
```

The slave-mqueue device should be created successfully.

Step 2: Create a fake responder
- mctp-smbus-test -r 8 0x24 0x28 8 9 (Note, is should use 8-bits slave address)

The response data is:
```
smbus: Invalid packet size
```
The fake responder should be created successfully and waiting for request data.


### Requester (EVB B)
- bus number 8
- slave address 0x12(7-bits) -> 0x24(8-bits)
- eid 8

Step 1: Create a slave-mqueue device
- echo slave-mqueue 0x12 > /sys/bus/i2c/devices/i2c-8/new_device (Note, it should use 7-bits slave address)
- ls /sys/bus/i2c/devices/i2c-8/8-0012/slave-mqueue

The response data is:

```
/sys/bus/i2c/devices/i2c-8/8-0012/slave-mqueue
```

The slave-mqueue device should be created successfully.

Step 2: Send MCTP control message (0x00) with Get Message Type Support command (0x05)
- mctp-smbus-test -t 8 0x28 0x24 9 8 0x00 0x80 0x05 (Note, it should use 8-bits slave address)

The response data is:

```
00 00 05 00 05
```

Step 3: Send MCTP control message (0x00) with Get Endpoint ID command (0x02)
- mctp-smbus-test -t 8 0x28 0x24 9 8 0x00 0x80 0x02 (Note, it should use 8-bits slave address)

The response data is:

```
00 00 02 05
```

Step 4: Send ASPEED echo message type (0x7c) with ECHO command (0x00)
- mctp-smbus-test -t 8 0x28 0x24 9 8 0x7c 0x80 0x00 0x01 0x02 0x03 0x04 0x05 (Note, it should use 8-bits slave address)

The response data is:

```
7c 00 00 00 01 02 03 04 05
```

Step 5: Send ASPEED echo message type (0x7c) with ECHO_LARGE command (0x01)
- mctp-smbus-test -t -l 32 8 0x28 0x24 9 8 0x7c 0x80 0x01 (Note, it should use 8-bits slave address)

The response data is:

```
7c 00 01 00 00 01 02 03 04 05 06 07 08 09 0a 0b 0c 0d 0e 0f 10 11 12 13 14 15 16 17 18 19 1a 1b 1c 1d 1e 1f
```

Step 6: Send ASPEED echo message type (0x7c) with unsupported command (0x03)
- mctp-smbus-test -t 8 0x28 0x24 9 8 0x7c 0x80 0x03 (Note, it should use 8-bits slave address)

The response data is:

```
7c 00 03 05
```
