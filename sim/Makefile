# Makefile

# defaults
SIM ?= icarus
TOPLEVEL_LANG ?= verilog

VERILOG_SOURCES += $(PWD)/../hdl/*
# use VHDL_SOURCES for VHDL files

# TOPLEVEL is the name of the toplevel module in your Verilog or VHDL file
TOPLEVEL = uw_sync_derotate_int
# TOPLEVEL = uw_deinterleave

# MODULE is the basename of the Python test file
# MODULE = test_uw_interleave_full
MODULE = test_uw_interleave_rot

# include cocotb's make rules to take care of the simulator setup
include $(shell cocotb-config --makefiles)/Makefile.sim
