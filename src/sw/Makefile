# RV32u software flow (spec 08-software-flow.md).
#
#   make            build every ISA test and C program into build/ (hex, listing, symbols)
#   make c/fib      one C program;  make isa/add  one ISA test
#   make clean
#
# Every image goes through check_subset.py, which fails the build if any instruction is
# outside the 14 of RV32u (except isa/trap_*, which contain one on purpose). C goes
# through legalize.py first: GCC -O0 uses a few instructions RV32u does not have (bne,
# bge, slli, seqz/snez), which it rewrites into subset sequences.

SW      := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
ROOT    := $(abspath $(SW)/../..)
MEM_CONFIG := $(ROOT)/src/hw/rtl/mem_ss/mem_config.svh
BUILD   := $(SW)/build
PYTHON  ?= python3

# Toolchain: the first prefix found on PATH (scripts/install-riscv-prebuilt.sh)
CROSS ?= $(firstword $(foreach p,riscv32-unknown-elf- riscv64-unknown-elf- riscv-none-elf-,\
           $(if $(shell command -v $(p)gcc 2>/dev/null),$(p))))
ifeq ($(CROSS),)
$(error no RISC-V GCC found (riscv32-unknown-elf-, riscv64-unknown-elf- or riscv-none-elf-): run scripts/install-riscv-prebuilt.sh)
endif
CC      := $(CROSS)gcc
OBJCOPY := $(CROSS)objcopy
OBJDUMP := $(CROSS)objdump
NM      := $(CROSS)nm

ARCH    := -march=rv32i -mabi=ilp32
CFLAGS  := $(ARCH) -O0 -ffreestanding -fno-builtin -fno-pic -mno-relax -Wall -Wextra
ASFLAGS := $(ARCH) -mno-relax
LDFLAGS := $(ARCH) -nostdlib -nostartfiles -Wl,--no-relax -Wl,--no-warn-rwx-segments \
           -Wl,-T,$(BUILD)/link.ld

# RAM size (decision D1: RV32U_RAM_WORDS in src/hw/rtl/mem_ss/mem_config.svh)
RAM_WORDS := $(shell sed -n 's/^`define RV32U_RAM_WORDS \([0-9]*\).*/\1/p' $(MEM_CONFIG))
RAM_BYTES := $(shell echo $$(( $(RAM_WORDS) * 4 )))

ISA := $(patsubst $(SW)/isa/%.S,isa/%,$(wildcard $(SW)/isa/*.S))
C   := $(patsubst $(SW)/c/%.c,c/%,$(wildcard $(SW)/c/*.c))

.PHONY: all clean $(ISA) $(C)
.SECONDARY:
all: $(ISA) $(C)

$(ISA) $(C): %: $(BUILD)/%.hex

$(BUILD)/link.ld: $(SW)/link.ld.in $(MEM_CONFIG)
	@mkdir -p $(@D)
	sed 's/@RAM_BYTES@/$(RAM_BYTES)/' $< > $@

# ISA tests: hand-written assembly, no crt0 (they start at address 0)
$(BUILD)/isa/%.elf: $(SW)/isa/%.S $(BUILD)/link.ld
	@mkdir -p $(@D)
	$(CC) $(ASFLAGS) $(LDFLAGS) -o $@ $<

# C programs: compile to assembly, legalize, then assemble and link with crt0
$(BUILD)/c/%.s: $(SW)/c/%.c
	@mkdir -p $(@D)
	$(CC) $(CFLAGS) -S -o $@ $<

$(BUILD)/c/%.legal.s: $(BUILD)/c/%.s $(SW)/legalize.py
	$(PYTHON) $(SW)/legalize.py $< -o $@

$(BUILD)/c/%.elf: $(BUILD)/c/%.legal.s $(SW)/crt0.S $(BUILD)/link.ld
	$(CC) $(ASFLAGS) $(LDFLAGS) -o $@ $(SW)/crt0.S $<

$(BUILD)/%.hex: $(BUILD)/%.elf $(SW)/check_subset.py $(SW)/bin2hex.py
	$(OBJDUMP) -d $< > $(BUILD)/$*.lst
	$(NM) -n $< > $(BUILD)/$*.sym
	$(if $(filter isa/trap_%,$*),@echo "$*: trap test (illegal instructions on purpose)",$(PYTHON) $(SW)/check_subset.py $< --objdump $(OBJDUMP))
	$(OBJCOPY) -O binary $< $(BUILD)/$*.bin
	$(PYTHON) $(SW)/bin2hex.py $(BUILD)/$*.bin $@ --ram-bytes $(RAM_BYTES)

clean:
	rm -rf -- "$(SW)/build"
