# test deinterleave module
import random
import cocotb
from cocotb.triggers import Timer
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge
from cocotb.types import LogicArray

def create_frames(sync_word, num_frames, offset):
    """Creates an list of frames. Each frame is 80 bits long. The first 8 bits are the sync word 
    and the remaining 72 are random bits. Result should just consist of one list
    """
    frames = []
    for i in range(offset):
        frames.append(random.randint(0,1))
    for i in range(num_frames):
        frames.extend(list(bin(sync_word)[2:].zfill(8)))
        for j in range(72):
            frames.append(random.randint(0,1))
    return [int(i) for i in frames]

@cocotb.test()
async def test_deinterleave(dut):
    """test 32 frames beginning with offset of 0"""
    # Assert initial output is unknown
    assert LogicArray(dut.valid_out.value) == LogicArray("X")

    # Set initial input value to prevent it from floating
    dut.valid_in.value = 0
    dut.rst_in.value = 0 

    clock = Clock(dut.clk, 100, units="us")  # Create a 10us period clock on port clk
    # Start the clock. Start it low to avoid issues on the first RisingEdge
    cocotb.start_soon(clock.start(start_high=False))

    await RisingEdge(dut.clk)
    dut.rst_in.value = 1
    await RisingEdge(dut.clk)

    # Feed in bits one at a time until the first 32 frames are received. Then should output the 
    # a bit offset of zero and a rotation of 0 (no rotation) with synch_word 0x27 

    frame_test = create_frames(0x27, 32, 0)
    while not dut.ready_rx.value == 1:
        await RisingEdge(dut.clk)

    for i in range(len(frame_test)):
        dut.hard_inp.value = frame_test[i]
        dut.valid_in.value = 1
        if (dut.valid_out.value == 1):
            print(dut.state_out.value)
            print("Found one")
        await RisingEdge(dut.clk)

        assert dut.valid_out.value == 0, f"output valid was incorrect on the {i}th cycle"
        # assert dut.bit_offset.value == LogicArray("X"), f"output offset was incorrect on the {i}th cycle"

    # Check the final input on the next clock
    # print(dut.state_out.value)
    while not dut.valid_out.value:
        await RisingEdge(dut.clk)
    
    assert dut.bit_offset.value == 0, \
        f"output bit_offset was incorrect on the {i}th cycle, expected 0, got {dut.bit_offset.value}"
    assert dut.rotation.value == 0, \
        f"output rotation was incorrect on the {i}th cycle, expected 0, got {dut.rotation.value}"

# @cocotb.test()
# async def test_deinterleave_offset_rot(dut):
#     """test 32 frames with an offset of 20"""
#     # Assert initial output is unknown
#     assert LogicArray(dut.valid_out.value) == LogicArray("X")
#     assert LogicArray(dut.bit_offset.value) == LogicArray("X")
#     assert LogicArray(dut.rotation.value) == LogicArray("X")
#     # Set initial input value to prevent it from floating
#     dut.valid_in.value = 0
#     dut.rst_in.value = 0 
    

#     clock = Clock(dut.clk, 100, units="us")  # Create a 10us period clock on port clk
#     # Start the clock. Start it low to avoid issues on the first RisingEdge
#     cocotb.start_soon(clock.start(start_high=False))

#     # Synchronize with the clock. This will regisiter the initial `d` value
#     await RisingEdge(dut.clk)
#     # Feed in bits one at a time until the first 32 frames are received. Then should output the 
#     # a bit offset of zero and a rotation of 0 (no rotation) with synch_word 0x27 

#     frame_test = create_frames(0x4E, 32, 20)
#     for i in range(32 * 80):
#         dut.valid_in.value = 1
#         dut.hard_inp.value = frame_test[i]
#         await RisingEdge(dut.clk)
#         assert dut.valid_out.value == 0, f"output valid was incorrect on the {i}th cycle"

#     # Check the final input on the next clock
    
#     await RisingEdge(dut.clk)
#     assert  dut.valid_out.value == 1, f"output valid was incorrect on the {i}th cycle"
#     assert dut.bit_offset.value == 20, f"output bit_offset was incorrect on the {i}th cycle"
#     assert dut.rotation.value == 1, f"output rotation was incorrect on the {i}th cycle"

#     dut.valid_in.value = 0
#     await RisingEdge(dut.clk)
#     assert dut.valid_out.value == 0, f"output valid was incorrect on the {i}th cycle"


# @cocotb.test()
# async def test_deinterleave_multiple_frames(dut):
#     """test 64 frames beginning with offset of 0"""
#     # Assert initial output is unknown
#     assert LogicArray(dut.valid_out.value) == LogicArray("X")
#     assert LogicArray(dut.bit_offset.value) == LogicArray("X")
#     assert LogicArray(dut.rotation.value) == LogicArray("X")
#     # Set initial input value to prevent it from floating
#     dut.valid_in.value = 0
#     dut.rst_in.value = 0 


#     clock = Clock(dut.clk, 100, units="us")  # Create a 10us period clock on port clk
#     # Start the clock. Start it low to avoid issues on the first RisingEdge
#     cocotb.start_soon(clock.start(start_high=False))

#     # Synchronize with the clock. This will regisiter the initial `d` value
#     await RisingEdge(dut.clk)
#     # Feed in bits one at a time until the first 32 frames are received. Then should output the 
#     # a bit offset of zero and a rotation of 0 (no rotation) with synch_word 0x27 

#     frame_test = create_frames(0xD8, 32, 47)
#     for i in range(32 * 80):
#         dut.valid_in.value = 1
#         dut.hard_inp.value = frame_test[i]
#         await RisingEdge(dut.clk)
#         assert dut.valid_out.value == 0, f"output valid was incorrect on the {i}th cycle"

#     # Check the final input on the next clock
#     await RisingEdge(dut.clk)
#     assert  dut.valid_out.value == 1, f"output valid was incorrect on the {i}th cycle"
#     assert dut.bit_offset.value == 47, f"output bit_offset was incorrect on the {i}th cycle"
#     assert dut.rotation.value == 2, f"output rotation was incorrect on the {i}th cycle"


#     frame_test = create_frames(0xD8, 32, 4)
#     for i in range(32 * 80):
#         dut.valid_in.value = 1
#         dut.hard_inp.value = frame_test[i]
#         await RisingEdge(dut.clk)
#         assert dut.valid_out.value == 0, f"output valid was incorrect on the {i}th cycle"

#     # Check the final input on the next clock
#     await RisingEdge(dut.clk)
#     assert  dut.valid_out.value == 1, f"output valid was incorrect on the {i}th cycle"
#     assert dut.bit_offset.value == 4, f"output bit_offset was incorrect on the {i}th cycle"
#     assert dut.rotation.value == 2, f"output rotation was incorrect on the {i}th cycle"
    

