## How to test secure connection with aspeed-pfr-tool

In this mode, the PFR works as responder to response the requests from aspeed-pfr-tool. The below options are added for secure connection feature.  
-E : enable secure connection  
-D : specify the MCTP destination endpoint id  
-n : specify MCTP network index  
-t : specify the test case id  

Example:  
To execute all test cases
```
aspeed-pfr-tool -E -t 0xff
```
To read mailbox register 0x60 with MCTP dest eid 8
```
aspeed-pfr-tool -E -D 8 -r 0x60
```
To display BMC/PCH version info with MCTP network 4
```
aspeed-pfr-tool -E -n 4 -i
```

Note 1: -n is used to specify the MCTP network index. This index can be found by issuing `mctp link` in BMC console. User needs to specify this index if there are two (or more) devices with the same eid in the different MCTP networks. The default value is 4 (for BMC).  
Note 2: -D is used to specify the MCTP destination endpoint id. If there are two or more endpoints in a bus, user need to specify this value for sending the MCTP packets. The default value is 0x8.  
Note 3: Each aspeed-pfr-tool command creates a secure connection. For example:  
```
aspeed-pfr-tool -E -p show
```
```
aspeed-pfr-tool -E -r 0x60
```
Both commands create one session during the command execution time.  

### Test cases in aspeed-pfr-tool
User could use the below test cases to verify the SPDM session related operations.

1. Burst heartbeat test : after a session is created, to send 10K heartbeat.
1. Heartbeat with random timeout : to simulate an application keeps a session with heartbeat.
1. Stress key update test : to execute key operation 10K rounds and verify a new key with a heartbeat.
1. Heartbeat timeout test : this is a negative test. To send a heartbeat after timeout is reached.
1. Write register test : to change and restore a register value 10K rounds.
1. Two performance tests : to measure the performance data for secure connection and non-secure connection.

## How to test secure connection with spdm_requester_emu
In this mode, the PFR works as responder to response the requests from spdm_requester_emu.
The below example is using i2c to establish secure connection.

```
pushd /usr/share/spdm-emu

spdm_requester_emu --ver 1.2 \
  --mctp_deid 0xb \
  --cap CERT,CHAL,KEY_UPD,ENCRYPT,MAC,HBEAT,HANDSHAKE_IN_CLEAR,KEY_EX,MUT_AUTH,ENCAP,CHUNK \
  --hash SHA_384 \
  --meas_spec DMTF \
  --meas_hash SHA_384 \
  --asym ECDSA_P384 \
  --req_asym ECDSA_P384 \
  --basic_mut_auth NO \
  --slot_id 0 \
  --mut_auth DIGESTS \
  --meas_sum ALL \
  --meas_op ONE_BY_ONE \
  --meas_att HASH \
  --exe_mode SHUTDOWN \
  --exe_conn DIGEST,CERT,CHAL,MEAS \
  --exe_session KEY_EX,HEARTBEAT,KEY_UPDATE \
  --key_upd ALL \
  --trans NONE

popd
```

The below example is using i3c to establish secure connection. If the device `/dev/i3c-mctp-target-0` is used for i3c MCTP transmission, i3c-attestation-emu.service must be stopped before testing secure connection function.

```
pushd /usr/share/spdm-emu

spdm_requester_emu --ver 1.2 \
  --mctp_medium 1 \
  --mctp_bus 0 \
  --mctp_sa 0x08 \
  --mctp_rot_sa 0x70 \
  --mctp_eid 0x0a \
  --cap CERT,CHAL,KEY_UPD,ENCRYPT,MAC,HBEAT,HANDSHAKE_IN_CLEAR,KEY_EX,MUT_AUTH,ENCAP,CHUNK \
  --hash SHA_384 \
  --meas_spec DMTF \
  --meas_hash SHA_384 \
  --asym ECDSA_P384 \
  --req_asym ECDSA_P384 \
  --basic_mut_auth BASIC \
  --slot_id 0 \
  --mut_auth DIGESTS \
  --meas_sum ALL \
  --meas_op ONE_BY_ONE \
  --meas_att HASH \
  --exe_mode SHUTDOWN \
  --exe_conn DIGEST,CERT,CHAL,MEAS \
  --exe_session KEY_EX,HEARTBEAT,KEY_UPDATE \
  --key_upd ALL \
  --trans NONE

popd
```

## How to test secure connection with spdm_responder_emu
In this mode, the PFR code works as requester to send the SPDM request to spdm_responder_emu.
The below example is using i3c to establish secure connection.

```
pushd /usr/share/spdm-emu

/usr/bin/spdm_responder_emu \
  --ver 1.2 \
  --mctp_medium 1 \
  --cap CERT,CHAL,MEAS_SIG,HBEAT,HANDSHAKE_IN_CLEAR,KEY_EX,MUT_AUTH,ENCAP,KEY_UPD,ENCRYPT,MAC \
  --hash SHA_384 \
  --meas_spec DMTF \
  --meas_hash SHA_384 \
  --asym ECDSA_P384 \
  --req_asym ECDSA_P384 \
  --basic_mut_auth NO \
  --slot_id 0 \
  --dhe SECP_384_R1 \
  --mut_auth DIGESTS \
  --meas_sum ALL \
  --meas_op ONE_BY_ONE \
  --meas_att HASH \
  --exe_mode SHUTDOWN \
  --exe_session KEY_EX,HEARTBEAT,KEY_UPDATE,MEAS \
  --exe_conn VER_ONLY,DIGEST,CERT,CHAL,MEAS \
  --key_upd ALL \
  --trans MCTP

popd
```

Note : In spdm_responder_emu code, it will detect the device `/dev/i3c-mctp-target-0` existed or not. If this device does not existed, it will switch to use MCTP network socket for receiving and sending the MCTP packets from I3C interface.

## How to use secure-test script
To upload the test script (`meta-aspeed-sdk/meta-aspeed-pfr/recipes-aspeed/aspeed-pfr-tool/aspeed-pfr-tool/test/secure-test`) to BMC side and issue `secure-test` to get more command detail.  

Now, secure-test script provides the below test scenarios.  

1. stress read test : to get different commands (-s, -i, or -p show) results from SMBus interface and compare the results with the data from secure connections.  
1. two concurrent secure sessions test : to establish two secure connections and send heartbeat at the same time. User can adjust the `-n` option for testing different MCTP network or I3C bus.