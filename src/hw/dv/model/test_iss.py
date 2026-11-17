"""Self-tests of the reference model (`uv run pytest`): the oracle must be right too."""

import pytest

from dv.model.rv32u_iss import Rv32uIss, decode, disassemble


def enc_i(op, rd, f3, rs1, imm):
    return ((imm & 0xFFF) << 20) | (rs1 << 15) | (f3 << 12) | (rd << 7) | op


def enc_r(rd, f3, rs1, rs2, f7=0):
    return (f7 << 25) | (rs2 << 20) | (rs1 << 15) | (f3 << 12) | (rd << 7) | 0b0110011


def enc_s(rs1, rs2, imm):
    return (((imm >> 5) & 0x7F) << 25) | (rs2 << 20) | (rs1 << 15) | (2 << 12) | (
        (imm & 0x1F) << 7) | 0b0100011


def enc_b(f3, rs1, rs2, imm):
    return ((((imm >> 12) & 1) << 31) | (((imm >> 5) & 0x3F) << 25) | (rs2 << 20) | (rs1 << 15)
            | (f3 << 12) | (((imm >> 1) & 0xF) << 8) | (((imm >> 11) & 1) << 7) | 0b1100011)


def enc_j(rd, imm):
    return ((((imm >> 20) & 1) << 31) | (((imm >> 1) & 0x3FF) << 21) | (((imm >> 11) & 1) << 20)
            | (((imm >> 12) & 0xFF) << 12) | (rd << 7) | 0b1101111)


HALT = enc_b(0, 0, 0, 0)  # beq x0, x0, 0


def run(words, ram=2048):
    iss = Rv32uIss(ram)
    iss.load_words(words)
    return iss, iss.run(1000)


def test_arithmetic_and_x0():
    iss, _ = run([enc_i(0b0010011, 5, 0, 0, -3), enc_i(0b0010011, 6, 0, 0, 7),
                  enc_r(7, 0, 5, 6), enc_r(8, 0, 5, 6, 0x20), enc_r(9, 2, 5, 6),
                  enc_r(10, 7, 5, 6), enc_r(11, 6, 5, 6), enc_i(0b0010011, 0, 0, 0, 5), HALT])
    x = iss.x
    assert x[7] == 4 and x[8] == (-10) & 0xFFFFFFFF and x[9] == 1
    assert x[10] == (-3 & 7) and x[11] == ((-3 & 0xFFFFFFFF) | 7) and x[0] == 0


def test_memory_and_branches():
    iss, rs = run([enc_i(0b0010011, 5, 0, 0, 0x100), enc_i(0b0010011, 6, 0, 0, 42),
                   enc_s(5, 6, 8), enc_i(0b0000011, 7, 2, 5, 8),
                   enc_b(0, 6, 7, 8), enc_i(0b0010011, 8, 0, 0, 1),  # skipped
                   enc_b(4, 0, 6, 8), enc_i(0b0010011, 9, 0, 0, 1),  # 0 < 42: skipped
                   HALT])
    assert iss.word(0x108) == 42 and iss.x[7] == 42 and iss.x[8] == 0 and iss.x[9] == 0
    sw = next(r for r in rs if r.name == "sw")
    assert (sw.mem_addr, sw.mem_wstrb, sw.mem_wdata) == (0x108, 0xF, 42)


def test_jumps_and_upper():
    iss, rs = run([enc_j(1, 8), HALT, (0x12345 << 12) | (10 << 7) | 0b0110111,
                   (0x1 << 12) | (11 << 7) | 0b0010111, enc_i(0b1100111, 0, 0, 1, 1)])
    assert iss.x[1] == 4 and iss.x[10] == 0x12345000 and iss.x[11] == 0x100C
    assert rs[-1].pc == 4 and rs[-1].halts  # jalr to (4+1)&~1 = 4, the halt


@pytest.mark.parametrize("words, trap_pc", [
    ([0x00001033], 0),                                    # sll: not in the subset
    ([enc_i(0b0010011, 5, 0, 0, 2), enc_i(0b0000011, 6, 2, 5, 0)], 4),  # misaligned LW
    ([enc_i(0b1100111, 0, 0, 0, 6)], 6),                  # jalr to 6: misaligned fetch
])
def test_traps(words, trap_pc):
    _, rs = run(words)
    assert rs[-1].trap and rs[-1].pc == trap_pc


def test_decode_rejects_rest_of_rv32i_and_disassembles():
    assert decode(0x00002013) is None      # slti
    assert decode(0x00001063) is None      # bne
    assert disassemble(enc_r(5, 0, 6, 7)) == "add t0, t1, t2"
    assert "not in RV32u" in disassemble(0x00001033)
