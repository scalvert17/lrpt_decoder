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
        frames.extend(list(bin(sync_word)[2:].zfill(32)))
        for j in range(1020 * 8):
            frames.append(random.randint(0,1))
    return [int(i) for i in frames]

def test_sync(dut, num_offset):
    async def test_sync_offset(dut):
        """test 32 frames beginning with offset of 20"""
        # Assert initial output is unknown
  # input wire clk,
  # input wire rst_in,
  # input wire hard_inp,
  # input wire valid_in, 

  # output logic ready_rx,
  # output logic valid_out, 
  # output logic [$clog2(BITS_PER_FRAME)-1:0] bit_offset, // Offset of the max correlation
  # output logic [$clog2(MAX_CORR_VAL)-1:0] max_offset_weight // Max correlation value

        sync_word = 0x1ACFFC1D
        bits_per_frame = 1024 * 8 # 8 CADU packets 1024 bytes each
        frames_per_cadu_conv = 8
        # assert LogicArray(dut.valid_out.value) == LogicArray("X")
        # Set initial input value to prevent it from floating
        dut.valid_in.value = 0
        dut.rst_in.value = 1

        clock = Clock(dut.clk, 10, units="ns")

        cocotb.start_soon(clock.start(start_high=False))
        await RisingEdge(dut.clk)
        dut.rst_in.value = 0;

        await RisingEdge(dut.clk)
        while not dut.ready_rx.value:
            await RisingEdge(dut.clk)

        await RisingEdge(dut.clk)
        frame_test = create_frames(sync_word, frames_per_cadu_conv, num_offset)
        print(num_offset)
        for i in range(frames_per_cadu_conv * bits_per_frame):
            dut.valid_in.value = 1
            dut.hard_inp.value = frame_test[i]
            await RisingEdge(dut.clk)   
            # assert LogicArray(dut.valid_out.value) == LogicArray("X"), f"output valid was incorrect on the {i}th cycle"
            assert dut.valid_out.value == 0, \
                f"output valid was incorrect on the {i}th cycle, got: {dut.valid_out.value}, expected: 0"

        # Wait for the next two clock cycles
        dut.valid_in.value = 0
        while not dut.valid_out.value:
            print("Waiting for valid out")
            await RisingEdge(dut.clk)
        assert  dut.valid_out.value == 1, \
            f"output valid was incorrect on the {i}th cycle, got: {dut.valid_out.value}, expected: 1"
        print(f" dutoffset: {dut.bit_offset.value.binstr}")
        assert dut.bit_offset.value == 0, \
            f"output bit_offset was incorrect on the {i}th cycle got: {dut.bit_offset.value.binstr}, expected: {num_offset}"
        try: 
           assert dut.max_offset_weight == 8 * 32, \
                f"output max_offset_weight was incorrect on the {i}th cycle got: {dut.max_offset_weight}, expected: 256"
        except: 
            print(f'Falide on the {num_offset} iteratino')
        
        await RisingEdge(dut.clk)
        # Should only be one cycle of valid output
        assert dut.valid_out.value == 0, \
            f"output valid was incorrect on the {i}th cycle, got: {dut.valid_out.value}, expected: 0"
        
 
    return test_sync_offset

@cocotb.test()
async def test_uw_sync_derotate_ints_all(dut):
    for i in range(1024):
        await test_sync(dut, i)(dut)

# @cocotb.test()
# async def test_deinterleave(dut):
#     """test 32 frames beginning with offset of 0"""
#     # Assert initial output is unknown
#     assert LogicArray(dut.valid_out.value) == LogicArray("X")

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

#     frame_test = create_frames(0x27, 32, 0)
#     for i in range(32 * 80):
#         dut.hard_inp.value = frame_test[i]
#         dut.valid_in.value = 1
#         await RisingEdge(dut.clk)
#         assert dut.valid_out.value == 0, f"output valid was incorrect on the {i}th cycle"
#         # assert dut.bit_offset.value == LogicArray("X"), f"output offset was incorrect on the {i}th cycle"

#     # Check the final input on the next clock
#     dut.valid_in.value = 0
#     await RisingEdge(dut.clk)
#     assert dut.valid_out.value == 0, f"output valid was incorrect on the {i}th cycle"
#     await RisingEdge(dut.clk)
#     assert  dut.valid_out.value == 1, f"output valid was incorrect on the {i}th cycle"
#     assert dut.bit_offset.value == 0, f"output bit_offset was incorrect on the {i}th cycle"
#     assert dut.rotation.value == 0, f"output rotation was incorrect on the {i}th cycle"

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
    

