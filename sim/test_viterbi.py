import random
import numpy as np
import asyncio
import cocotb
from cocotb.triggers import Timer
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge
from cocotb.types import LogicArray
from viterbi import ViterbiDecoder
from cocotb.triggers import ReadOnly

def conv_calc(state, in_bit, noise=False):
  # returns the output (i, q) for the given input state
  g1 = ((in_bit << 6) | state) & 0b1111001
  g2 = ((in_bit << 6) | state) & 0b1011011
  if not noise:
      return convert_to_signed_rep((count_ones(g1), count_ones(g2)))
  midpts = [0xC0 if not i else 0x3F for i in (count_ones(g1), count_ones(g2))]
  return [max(-128, (b + int(random.gauss(0, 15))), 127) & 0xff \
            for b in midpts]

def count_ones(n):
  return bin(n).count('1') % 2

@cocotb.coroutine
async def monitor_acs_output(dut, soft, states, inputs,  eps=0):
# read the nth step on viterbi python, keep track of inputs so that we can sees this
    # while True:
    #     await RisingEdge(dut.clk)
    #     print(f'dut.met_out_TBU_deb.value: {dut.met_out_TBU_deb.value}')

    trellis_step = 0
    await RisingEdge(dut.valid_in_TBU_deb)
    await RisingEdge(dut.clk)
    while True:
        if (trellis_step < 5):
            vit_states = soft.get_prev_states(trellis_step + 1)
            print(f'dut.met_out_TBU_deb.value: {dut.met_out_TBU_deb.value}')
            j = dut.prev_state_TBU_deb.value
            print("__________SM_DUT___")
            print([k.integer for k in dut.sm_TBU_deb.value])
            print("_____Desc_DUT_________")
            print([k.integer for k in dut.desc_TBU_deb.value])
            print("_____________DUT__________")
            print([k.integer for k in dut.prev_state_TBU_deb.value])
            print("____VIT_______")
            print(vit_states)
            # assert (vit_states[64-k-1]) == (dut.prev_state_TBU_deb.value[k].integer), \
            #         f"Fail on step {trellis_step} and state {k}"
            assert dut.sm_TBU_deb.value[states[trellis_step]].integer == 0, \
                f"Expected small state metric for state: {states[trellis_step]} \
                    on step: {trellis_step}"              
            assert dut.desc_TBU_deb.value[states[trellis_step]] == inputs[trellis_step], \
                f"Expected correct output decision from state: {states[trellis_step]}, \
                    expected: {inputs[trellis_step]}"
            trellis_step += 1
        await RisingEdge(dut.clk)

def convert_to_signed_rep(inp): 
    """ Converts an array of zeros and ones to 8 bit hex values where 0 maps to 8'h80 and 
    1 maps to 8'h7F
    """
    return [0x80 if not i else 0x7F for i in inp]



@cocotb.coroutine
async def vit_desc_exp(dut, inp_size, inputs):
    ind = 0
    while True:
        if (dut.valid_out_vit.value == 1):
            print("ind: ", ind)
            assert dut.vit_desc == inputs[ind], f"Expected vit_out: {inputs[ind]} instead got:  \
                    {dut.vit_desc} on timestep: {ind}"
            ind += 1
        await RisingEdge(dut.clk)


# async def read_out_vit_desc(dut, max_inp):
#     count = 0
#     while True: 
#         if (dut.valid_out_vit.value == 1):
#             yield dut.vit_desc.value
#             count += 1
#         # if (count == max_inp - 1):
#         #     for _ in range(10):
#         #         await RisingEdge(dut.clk)
#         #         assert dut.valid_out_vit.value == 0, f"Expected only {max_inp} desc to be had"
#         await RisingEdge(dut.clk)

async def test_viterbi(dut, inp_size, noise=False):
    K, glist = 7, (0b1111001, 0b1011011)
    soft = ViterbiDecoder(K, glist)
    dut.valid_in_vit.value = 0
    dut.sys_rst.value = 0 

    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start(start_high=False))

    await RisingEdge(dut.clk)
    dut.sys_rst.value = 1
    await RisingEdge(dut.clk)
    dut.sys_rst.value = 0

    state = 0b000000
    inp_bit = 1
    out_seen = []
    states = []
    inputs = []
    for i in range(inp_size):
        out_seen.extend(conv_calc(state, inp_bit, noise))
        state = ((state >> 1) | (inp_bit << 5)) & 0b111111
        inputs.append(inp_bit)
        states.append(state)
        inp_bit = 1 if not inp_bit else 0

    soft.decode(np.array(out_seen))
    # print(f'Expected output: {inputs}')

    # cocotb.start_soon(monitor_acs_output(dut, soft, states, inputs))
    cocotb.start_soon(vit_desc_exp(dut, inp_size, inputs))

    for i in range(inp_size):
        while not random.random() > 0.5:
            dut.valid_in_vit.value = 0
            await RisingEdge(dut.clk)
        dut.valid_in_vit.value = 1
        dut.soft_inp.value = out_seen[2*i]
        await RisingEdge(dut.clk)   
        dut.soft_inp.value = out_seen[2*i + 1]
        await RisingEdge(dut.clk)

    # Wait for the next two clock cycles
    dut.valid_in_vit.value = 0
    for _ in range(500):
        await RisingEdge(dut.clk)


@cocotb.test()
async def test_viterbi_clean(dut):
    """ Tests decoder on hard input values. Randomized variable delay between sets of i, q 
        input pairs """
    inp_size = 140 # Num of i,q pairs
    await test_viterbi(dut, inp_size, noise=False)

@cocotb.test()
async def viterbi_test_noise(dut):
    """ Tests decoder on i/q values with some additive noise. Randomized variable delay between
    sets of i,q input pairs"""
    inp_size = 300 # Num of i,q pairs
    await test_viterbi(dut, inp_size, noise=True)
