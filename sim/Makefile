# Makefile

# defaults
SIM ?= icarus
TOPLEVEL_LANG ?= verilog

# VERILOG_SOURCES += $(PWD)/../hdl/*
# use VHDL_SOURCES for VHDL files
VERILOG_SOURCES += $(PWD)/../hdl/acs_but.sv $(PWD)/../hdl/bmu.sv $(PWD)/../hdl/viterbi.sv \
				$(PWD)/../hdl/xilinx_true_dual_port_read_first_2_clock_ram.v $(PWD)/../hdl/tbu.sv

# TOPLEVEL is the name of the toplevel module in your Verilog or VHDL file
# TOPLEVEL = uw_sync_derotate_int
# TOPLEVEL = uw_deinterleave
# TOPLEVEL = uw_cadu
TOP_LEVEL = viterbi

# MODULE is the basename of the Python test file
# MODULE = test_uw_interleave_full
# MODULE = test_uw_interleave_rot
# MODULE = test_uw_cadu
MODULE = test_viterbi

# include cocotb's make rules to take care of the simulator setup

include $(shell cocotb-config --makefiles)/Makefile.sim
