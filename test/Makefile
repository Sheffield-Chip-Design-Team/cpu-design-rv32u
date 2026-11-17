# Tiny Tapeout cocotb test (the TT GDS action's gl_test runs this with GATES=yes).
# See https://docs.cocotb.org/en/stable/quickstart.html for more info.
#
#   make                 RTL smoke test of tt_um_sharc_rv32u (Icarus)
#   make GATES=yes       the same test on the gate-level netlist (the GDS action copies it in)
#
# The real verification of the core is the FuseSoC flow at the repo root (`make test`,
# spec 09); this test checks the Tiny Tapeout top level as the chip sees it.

# defaults
SIM ?= icarus
FST ?= -fst # Use more efficient FST format
TOPLEVEL_LANG ?= verilog
SRC_DIR = $(PWD)/../src

# Source files are read from the `source_files` list in ../info.yaml
INFO_YAML ?= $(PWD)/../info.yaml
PROJECT_SOURCES := $(shell awk ' \
	/^[[:space:]]*source_files:/ { f = 1; next } \
	f && /^[[:space:]]*-/ { sub(/\043.*/, ""); sub(/^[[:space:]]*-[[:space:]]*/, ""); gsub(/["\047[:space:]]/, ""); if ($$0 != "") print; next } \
	f && !/^[[:space:]]*(\043|$$)/ { exit }' $(INFO_YAML))
ifeq ($(strip $(PROJECT_SOURCES)),)
$(error No source_files found in $(INFO_YAML))
endif

# SystemVerilog, the IHP SRAM models' functional path, and no SRAM black boxes
COMPILE_ARGS += -g2012 -DSIM -DFUNCTIONAL
COMPILE_ARGS += -I$(SRC_DIR)/hw/rtl/cpu_ss

ifneq ($(GATES),yes)

# RTL simulation: the SRAM models come from the ip/IHP-Open-PDK submodule
# (scripts/init-submodules.sh)
SIM_BUILD       = sim_build/rtl
SRAM_MODELS    ?= $(PWD)/../ip/IHP-Open-PDK/ihp-sg13g2/libs.ref/sg13g2_sram/verilog
VERILOG_SOURCES += $(addprefix $(SRC_DIR)/,$(PROJECT_SOURCES))

else

# Gate level simulation:
SIM_BUILD       = sim_build/gl
COMPILE_ARGS    += -DGL_TEST
# Cell models for the PDK in $(PDK) (ihp-sg13cmos5l or ihp-sg13g2), e.g. sg13cmos5l_stdcell.v
PDK ?= ihp-sg13cmos5l
PDK_CELL_PREFIX = $(patsubst ihp-%,%,$(PDK))
PDK_LIBS_REF = $(PDK_ROOT)/$(PDK)/libs.ref
VERILOG_SOURCES += $(PDK_LIBS_REF)/$(PDK_CELL_PREFIX)_io/verilog/$(PDK_CELL_PREFIX)_io.v
# Newer PDK versions ship the UDP (user-defined primitive) models in a separate file
VERILOG_SOURCES += $(wildcard $(PDK_LIBS_REF)/$(PDK_CELL_PREFIX)_stdcell/verilog/$(PDK_CELL_PREFIX)_udp.v)
VERILOG_SOURCES += $(PDK_LIBS_REF)/$(PDK_CELL_PREFIX)_stdcell/verilog/$(PDK_CELL_PREFIX)_stdcell.v
# The SRAM models installed with the PDK (sg13cmos5l_sram is a link to sg13g2_sram)
SRAM_MODELS    ?= $(PDK_LIBS_REF)/$(PDK_CELL_PREFIX)_sram/verilog

# this gets copied in by the GDS action workflow
VERILOG_SOURCES += $(PWD)/gate_level_netlist.v

endif

# Behavioural models of the IHP SRAM macros (used if your RAM has macros, D1)
VERILOG_SOURCES += $(wildcard $(SRAM_MODELS)/RM_IHPSG13_1P_core_behavioral_bm_bist.v)
VERILOG_SOURCES += $(wildcard $(SRAM_MODELS)/RM_IHPSG13_1P_512x32_c2_bm_bist.v)
VERILOG_SOURCES += $(wildcard $(SRAM_MODELS)/RM_IHPSG13_1P_512x16_c2_bm_bist.v)

# Include the testbench sources:
VERILOG_SOURCES += $(PWD)/tb.v
TOPLEVEL = tb

# List test modules to run, separated by commas and without the .py suffix:
COCOTB_TEST_MODULES = test

# include cocotb's make rules to take care of the simulator setup
include $(shell cocotb-config --makefiles)/Makefile.sim
