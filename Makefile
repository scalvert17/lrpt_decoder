SOURCES :=                                      \
    hdl/                                        \
    obj/                                        \
    xdc/                                        \
    sim/                                        \

.PHONY: flash
flash:
		openFPGALoader -b arty_s7_50 obj/final.bit

.PHONY: build
build:
		./remote/r.py build.py build.tcl $(SOURCES)

.PHONY: correlator
correlator:
	iverilog -g2012 -o vcd/corr.out sim/correlator_tb.sv hdl/uw_deinterleave.sv
	vvp vcd/corr.out

.PHONY: uw_sync_full
uw_sync_full:
	iverilog -g2012 -o vcd/sync_full.out sim/uw_interleave_full_tb.sv hdl/uw_deinterleave.sv \
		hdl/xilinx_true_dual_port_read_first_2_clock_ram.v 
	vvp vcd/sync_full.out

.PHONY: bmu
bmu:
	iverilog -g2012 -o vcd/bmu.out sim/bmu_tb.sv hdl/bmu.sv
	vvp vcd/bmu.out
	
.PHONY: viterbi
viterbi:
	iverilog -g2012 -o vcd/viterbi.out sim/viterbi_tb.sv hdl/viterbi.sv hdl/acs_but.sv hdl/bmu.sv \
		hdl/tbu.sv hdl/xilinx_true_dual_port_read_first_2_clock_ram.v
	vvp vcd/viterbi.out

.PHONY: tbu
tbu:
	iverilog -g2012 -o vcd/tbu.out sim/tbu_tb.sv hdl/tbu.sv \
		hdl/xilinx_true_dual_port_read_first_2_clock_ram.v
	vvp vcd/tbu.out

# .PHONY: uw_sync_deint
# uw_sync_deint:
#     iverilog -g2012 -o vcd/uw_sync.out sim/uw_sync_interleave_tb.sv hdl/uw_deinterleave.sv
#     vvp vcd/sync_uw.out

.PHONY: clean
clean:
		rm -rf obj/*
		rm -rf vcd/*
		rm -rf vivado.log
