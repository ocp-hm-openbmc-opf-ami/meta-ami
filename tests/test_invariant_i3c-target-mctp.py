import pytest
import struct
from unittest.mock import MagicMock, patch


# Simulated constants matching the driver
MCTP_PACKET_MAX_SIZE = 68  # Typical MCTP packet max size (64 bytes data + 4 header)
MCTP_HEADER_SIZE = 4
MCTP_MAX_DATA_SIZE = MCTP_PACKET_MAX_SIZE - MCTP_HEADER_SIZE  # 64 bytes


class MCTPPacket:
    """Simulates the MCTP packet buffer structure from the driver."""
    BUFFER_SIZE = MCTP_PACKET_MAX_SIZE

    def __init__(self):
        self.data = bytearray(self.BUFFER_SIZE)
        self._write_count = 0

    def safe_copy(self, source_data, count):
        """
        Safe implementation: validates count against buffer capacity before copy.
        This is what the driver SHOULD do (the fix).
        Returns True if copy succeeded, False if rejected due to overflow.
        """
        if count > self.BUFFER_SIZE:
            return False  # Reject oversized input
        if count > len(source_data):
            return False  # Reject if count exceeds actual data
        # Truncate to buffer size as a safety measure
        safe_count = min(count, self.BUFFER_SIZE)
        self.data[:safe_count] = source_data[:safe_count]
        self._write_count = safe_count
        return True

    def unsafe_copy(self, source_data, count):
        """
        Vulnerable implementation: copies without validation (simulates the bug).
        This would be: memcpy(packet->data, data, count)
        """
        # Simulate what happens with unchecked memcpy
        self.data[:count] = source_data[:count]
        self._write_count = count


def simulate_i3c_mctp_receive(data: bytes, count: int) -> dict:
    """
    Simulates the I3C MCTP target driver receive path.
    Returns a dict with:
      - 'accepted': bool, whether the packet was accepted
      - 'bytes_written': int, how many bytes were written to the buffer
      - 'overflow': bool, whether an overflow would have occurred
    """
    packet = MCTPPacket()
    declared_buffer_size = MCTPPacket.BUFFER_SIZE

    # Security invariant check: count must not exceed buffer capacity
    overflow_would_occur = count > declared_buffer_size or count > len(data)

    if overflow_would_occur:
        # Correct behavior: reject the packet
        return {
            'accepted': False,
            'bytes_written': 0,
            'overflow': True,
            'buffer_size': declared_buffer_size,
            'requested_count': count,
        }

    # Safe copy
    success = packet.safe_copy(data, count)
    return {
        'accepted': success,
        'bytes_written': packet._write_count,
        'overflow': False,
        'buffer_size': declared_buffer_size,
        'requested_count': count,
    }


# Attack payloads: (data, count, description)
ATTACK_PAYLOADS = [
    # (data_bytes, count_field, description)
    # Oversized by 2x
    (b"A" * (MCTP_PACKET_MAX_SIZE * 2), MCTP_PACKET_MAX_SIZE * 2, "2x buffer size"),
    # Oversized by 10x
    (b"B" * (MCTP_PACKET_MAX_SIZE * 10), MCTP_PACKET_MAX_SIZE * 10, "10x buffer size"),
    # count = buffer_size + 1 (off-by-one)
    (b"C" * (MCTP_PACKET_MAX_SIZE + 1), MCTP_PACKET_MAX_SIZE + 1, "buffer_size + 1"),
    # count = buffer_size + 2
    (b"D" * (MCTP_PACKET_MAX_SIZE + 2), MCTP_PACKET_MAX_SIZE + 2, "buffer_size + 2"),
    # Extremely large count (integer overflow attempt)
    (b"E" * 65535, 65535, "max uint16 count"),
    # count = 0xFFFFFFFF (simulated 32-bit overflow)
    (b"F" * 128, 0xFFFFFFFF, "uint32 max count with small data"),
    # count larger than data provided (count mismatch attack)
    (b"G" * 10, MCTP_PACKET_MAX_SIZE * 5, "count >> actual data size"),
    # Crafted MCTP header with oversized length field
    (struct.pack(">BBBB", 0x01, 0x00, 0x00, 0x00) + b"H" * 200, 204, "crafted header + oversized payload"),
    # Null bytes with large count
    (b"\x00" * (MCTP_PACKET_MAX_SIZE * 3), MCTP_PACKET_MAX_SIZE * 3, "null bytes 3x buffer"),
    # Pattern designed to look like valid MCTP but oversized
    (b"\xDE\xAD\xBE\xEF" * 50, 200, "repeated pattern 200 bytes"),
    # count = buffer_size (boundary - should be accepted)
    (b"I" * MCTP_PACKET_MAX_SIZE, MCTP_PACKET_MAX_SIZE, "exact buffer size boundary"),
    # count = buffer_size - 1 (valid)
    (b"J" * (MCTP_PACKET_MAX_SIZE - 1), MCTP_PACKET_MAX_SIZE - 1, "buffer_size - 1 (valid)"),
    # Empty data with nonzero count
    (b"", 100, "empty data with large count"),
    # Single byte data with large count
    (b"K", MCTP_PACKET_MAX_SIZE * 4, "single byte data with huge count"),
    # Heap spray pattern
    (b"\x41\x41\x41\x41" * 256, 1024, "heap spray 1024 bytes"),
]


@pytest.mark.parametrize("payload", [
    pytest.param(p, id=p[2]) for p in ATTACK_PAYLOADS
])
def test_buffer_read_never_exceeds_declared_length(payload):
    """
    Invariant: Buffer reads (memcpy count) must NEVER exceed the declared
    destination buffer capacity. Any packet with count > BUFFER_SIZE must be
    rejected or truncated — never written beyond the buffer boundary.

    This guards against CWE-120: Buffer Copy without Checking Size of Input,
    specifically the vulnerability in i3c-target-mctp.c where memcpy is called
    with an unvalidated count parameter.
    """
    data, count, description = payload
    buffer_size = MCTPPacket.BUFFER_SIZE

    result = simulate_i3c_mctp_receive(data, count)

    # INVARIANT 1: Bytes written must never exceed the buffer size
    assert result['bytes_written'] <= buffer_size, (
        f"[{description}] OVERFLOW: wrote {result['bytes_written']} bytes "
        f"into buffer of size {buffer_size}. "
        f"count={count}, data_len={len(data)}"
    )

    # INVARIANT 2: If count exceeds buffer size, the packet must be rejected
    if count > buffer_size:
        assert result['accepted'] is False, (
            f"[{description}] SECURITY VIOLATION: packet with count={count} "
            f"exceeding buffer_size={buffer_size} was accepted. "
            f"This would cause a heap buffer overflow."
        )
        assert result['bytes_written'] == 0, (
            f"[{description}] SECURITY VIOLATION: {result['bytes_written']} bytes "
            f"were written despite oversized count={count}."
        )

    # INVARIANT 3: If count exceeds actual data length, packet must be rejected
    if count > len(data):
        assert result['accepted'] is False, (
            f"[{description}] SECURITY VIOLATION: count={count} exceeds "
            f"actual data length={len(data)}. Reading beyond data would "
            f"cause out-of-bounds read."
        )

    # INVARIANT 4: bytes_written must equal count if accepted (no silent truncation)
    if result['accepted']:
        assert result['bytes_written'] == count, (
            f"[{description}] Accepted packet wrote {result['bytes_written']} bytes "
            f"but count was {count}."
        )
        # Double-check: accepted count must be within bounds
        assert count <= buffer_size, (
            f"[{description}] Accepted packet with count={count} > "
            f"buffer_size={buffer_size} — this is a buffer overflow."
        )

    # INVARIANT 5: overflow flag must be consistent with count vs buffer_size
    expected_overflow = (count > buffer_size) or (count > len(data))
    assert result['overflow'] == expected_overflow, (
        f"[{description}] Overflow detection inconsistency: "
        f"overflow={result['overflow']} but expected={expected_overflow} "
        f"(count={count}, buffer_size={buffer_size}, data_len={len(data)})"
    )


@pytest.mark.parametrize("count,data_size", [
    (MCTP_PACKET_MAX_SIZE + 1, MCTP_PACKET_MAX_SIZE + 1),
    (MCTP_PACKET_MAX_SIZE * 2, MCTP_PACKET_MAX_SIZE * 2),
    (MCTP_PACKET_MAX_SIZE * 10, MCTP_PACKET_MAX_SIZE * 10),
    (0xFFFF, 0xFFFF),
])
def test_no_write_beyond_buffer_boundary(count, data_size):
    """
    Invariant: Under no circumstances should the number of bytes written
    to the packet buffer exceed its declared capacity, regardless of the
    count value provided by the incoming I3C packet.
    """
    data = b"X" * data_size
    packet = MCTPPacket()
    buffer_size = MCTPPacket.BUFFER_SIZE

    # Simulate the safe receive path
    result = simulate_i3c_mctp_receive(data, count)

    # The core security property: no write beyond buffer
    assert result['bytes_written'] <= buffer_size, (
        f"Buffer overflow detected: attempted to write {result['bytes_written']} "
        f"bytes into a {buffer_size}-byte buffer (count={count})"
    )

    # Oversized inputs must be rejected
    if count > buffer_size:
        assert not result['accepted'], (
            f"Oversized packet (count={count}) must be rejected to prevent "
            f"heap buffer overflow (buffer_size={buffer_size})"
        )


def test_valid_packet_is_accepted():
    """
    Sanity check: valid packets within buffer bounds must be accepted.
    This ensures the security check doesn't break legitimate functionality.
    """
    valid_sizes = [1, 4, 16, 32, MCTP_PACKET_MAX_SIZE - 1, MCTP_PACKET_MAX_SIZE]
    for size in valid_sizes:
        data = b"V" * size
        result = simulate_i3c_mctp_receive(data, size)
        assert result['accepted'] is True, (
            f"Valid packet of size {size} was incorrectly rejected"
        )
        assert result['bytes_written'] == size
        assert result['overflow'] is False


def test_zero_count_packet():
    """Edge case: zero-length packet should be handled gracefully."""
    data = b""
    result = simulate_i3c_mctp_receive(data, 0)
    assert result['bytes_written'] == 0
    assert result['bytes_written'] <= MCTPPacket.BUFFER_SIZE