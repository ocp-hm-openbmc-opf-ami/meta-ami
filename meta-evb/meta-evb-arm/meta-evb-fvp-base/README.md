# MegaRAC OneTree as Reference Implementation for Arm FVP

Author: Mohammed Javith Akthar M (mohammedjavitham@ami.com)

Created: September 4, 2026

## Problem Description

Fixed Virtual Platforms (FVPs) simulate a complete Arm system,
including its processors, memory, and peripherals. FVP enables early
firmware development and functional validation during the pre-silicon
stage, before (tapeout) target hardware is available.

This layer implements MegaRAC OneTree as a reference implementation
for the Arm Base RevC AEM FVP and connects it to the Neoverse
RD-V3-R1 FVP for host-management validation.

## Background and References

The Base FVP represents the BMC. The Neoverse RD-V3-R1 FVP represents
the host platform and contains the Application Processor (AP) and
Manageability Control Processor (MCP).

MegaRAC OneTree extends the upstream OpenBMC reference implementation
with expanded functionality.

References:

- [Neoverse Reference Software - BMC](https://neoverse-reference-design.docs.arm.com/en/latest/features/bmc.html)
- [ocp-hm-openbmc-opf-ami/docs](https://github.com/ocp-hm-openbmc-opf-ami/docs)

## Proposed Design

The Base FVP and RD-V3-R1 FVP run as separate processes on the same
Linux host. Keeping these process boundaries reflects the deployed
configuration, while connecting them through UART and virtual network
interfaces creates a complete reference-board environment.

```
+---------------- Base FVP ----------------+       +------------- RD-V3-R1 FVP ----------------+
| BMC [MegaRAC OneTree]                    |       | Host Reference Platform                   |
|                                          |       |                                           |
|                                          |       | +---------------- MCP ------------------+ |
|                                          |       | | [Silicon Firmware]                    | |
| UART                                     |       | |                                       | |
|   PL011 terminal_0 [debug]               |       | | UART                                  | |
|   PL011 terminal_1 <-- PLDM over MCTP over UART -----> PL011 terminal2                     | |
|   PL011 terminal_2 <-- IPMI over UART ---------+ | |   PL011 terminal_uart_mcp [debug]     | |
|   PL011 terminal_3 <-- Host serial console -+  ! | +---------------------------------------+ |
|                                          |  |  | |                                           |
|                                          |  |  | | +---------------- AP -------------------+ |
|                                          |  |  | | | [UEFI Firmware]                       | |
|                                          |  |  | | |                                       | |
|                                          |  |  | | | UART                                  | |
|                                          |  |  +-----> PL011 terminal3                     | |
|                                          |  +--------> PL011 terminal_ns_uart0 [debug]     | |
|                                          |       | |                                       | |
| NIC                                      |       | | NIC                                   | |
|    SMSC 91c111  RedfishHI <--+           |       | |   VirtIO-net  tap0                    | |
|    VirtIO-net   BmcNic       |           |       | |    ^                                  | |
|                     ^        |           |       | +----|----------------------------------+ |
+---------------------|--------|-----------+       +------|------------------------------------+
                      |        |                          |
                      |        +--------------------------+
                      |                                   |
                      v                                   v
       +--------------+-----------------------------------+------------------+
       |                     virbr0 (TAP/TUN bridge)                         |
       +---------------------------------------------------------------------+
```

| Acronyms         | Description                     |
|------------------|---------------------------------|
| Base FVP         | BMC virtual platform            |
| RD-V3-R1 FVP     | Host reference platform         |
| AP               | Application Processor           |
| MCP              | Manageability Control Processor |
| TAP/TUN          | Virtual Network Interface       |
| MegaRAC OneTree  | BMC Firmware                    |
| UEFI Firmware    | Host Boot Firmware              |
| Silicon Firmware | Arm Silicon Management Firmware |

### Management Interface

| Interface   | Use case                                                      |
|-------------|---------------------------------------------------------------|
| Out-of-band | `BmcNic` - SSH, IPMI, Redfish, SOL                            |
| In-band     | `RedfishHI` - Redfish, IPMI                                   |
| In-band     | `IPMI Serial` - UEFI IPMI                                     |
| Side-band   | `PLDM over MCTP over UART` - Sensor telemetry and CPER events |
