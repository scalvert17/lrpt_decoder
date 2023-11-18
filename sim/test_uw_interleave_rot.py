# test deinterleave module
import random
import cocotb
from cocotb.triggers import Timer
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge
from cocotb.types import LogicArray
from test_uw_interleave_full import create_frames

@cocotb.test()
async def test_uw_sync_derotate_int(dut):
    """test 32 frames beginning with offset of 0"""
    # Assert initial output is unknown

    assert LogicArray(dut.valid_out.value) == LogicArray("X")
    # Set initial input value to prevent it from floating
    dut.valid_in.value = 0
    dut.rst_in.value = 0 

    clock = Clock(dut.clk, 10, units="ns")

    cocotb.start_soon(clock.start(start_high=False))

    await RisingEdge(dut.clk)

    frame_test = create_frames(0x27, 32, 0)
    for i in range(32 * 80):
        dut.valid_in.value = 1
        dut.hard_inp.value = frame_test[i]
        await RisingEdge(dut.clk)   
        # assert LogicArray(dut.valid_out.value) == LogicArray("X"), f"output valid was incorrect on the {i}th cycle"
        assert dut.valid_out.value == 0, \
            f"output valid was incorrect on the {i}th cycle, got: {dut.valid_out.value}, expected: 0"

    # Wait for the next two clock cycles
    dut.valid_in.value = 0
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)

    assert  dut.valid_out.value == 1, f"output valid was incorrect on the {i}th cycle"
    print(f" dutoffset: {dut.bit_offset.value.binstr}")
    assert dut.bit_offset.value == 0, f"output bit_offset was incorrect on the {i}th cycle"


@cocotb.test()
async def test_uw_sync_derotate_int_20(dut):
    """test 32 frames beginning with offset of 20"""
    # Assert initial output is unknown

    # assert LogicArray(dut.valid_out.value) == LogicArray("X")
    # Set initial input value to prevent it from floating
    dut.valid_in.value = 0
    dut.rst_in.value = 1

    clock = Clock(dut.clk, 10, units="ns")

    cocotb.start_soon(clock.start(start_high=False))
    await RisingEdge(dut.clk)
    dut.rst_in.value = 0;

    await RisingEdge(dut.clk)

    frame_test = create_frames(0x27, 32, 20)
    for i in range(32 * 80):
        dut.valid_in.value = 1
        dut.hard_inp.value = frame_test[i]
        await RisingEdge(dut.clk)   
        # assert LogicArray(dut.valid_out.value) == LogicArray("X"), f"output valid was incorrect on the {i}th cycle"
        assert dut.valid_out.value == 0, \
            f"output valid was incorrect on the {i}th cycle, got: {dut.valid_out.value}, expected: 0"

    # Wait for the next two clock cycles
    dut.valid_in.value = 0
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)

    assert  dut.valid_out.value == 1, \
        f"output valid was incorrect on the {i}th cycle, got: {dut.valid_out.value}, expected: 1"
    print(f" dutoffset: {dut.bit_offset.value.binstr}")
    assert dut.bit_offset.value == 20, \
        f"output bit_offset was incorrect on the {i}th cycle got: {dut.bit_offset.value.binstr}, expected: 20"
    assert dut.max_offset_weight == 8 * 32, \
        f"output max_offset_weight was incorrect on the {i}th cycle got: {dut.max_offset_weight}, expected: 256"


def test_sync(dut, num_offset):
    async def test_sync_offset(dut):
        """test 32 frames beginning with offset of 20"""
        # Assert initial output is unknown

        # assert LogicArray(dut.valid_out.value) == LogicArray("X")
        # Set initial input value to prevent it from floating
        dut.valid_in.value = 0
        dut.rst_in.value = 1

        clock = Clock(dut.clk, 10, units="ns")

        cocotb.start_soon(clock.start(start_high=False))
        await RisingEdge(dut.clk)
        dut.rst_in.value = 0;

        await RisingEdge(dut.clk)

        frame_test = create_frames(0x27, 32, num_offset)
        for i in range(32 * 80):
            dut.valid_in.value = 1
            dut.hard_inp.value = frame_test[i]
            await RisingEdge(dut.clk)   
            # assert LogicArray(dut.valid_out.value) == LogicArray("X"), f"output valid was incorrect on the {i}th cycle"
            assert dut.valid_out.value == 0, \
                f"output valid was incorrect on the {i}th cycle, got: {dut.valid_out.value}, expected: 0"

        # Wait for the next two clock cycles
        dut.valid_in.value = 0
        await RisingEdge(dut.clk)
        await RisingEdge(dut.clk)

        assert  dut.valid_out.value == 1, \
            f"output valid was incorrect on the {i}th cycle, got: {dut.valid_out.value}, expected: 1"
        print(f" dutoffset: {dut.bit_offset.value.binstr}")
        assert dut.bit_offset.value == num_offset, \
            f"output bit_offset was incorrect on the {i}th cycle got: {dut.bit_offset.value.binstr}, expected: {num_offset}"

        await RisingEdge(dut.clk)
        # Should only be one cycle of valid output
        assert dut.valid_out.value == 0, \
            f"output valid was incorrect on the {i}th cycle, got: {dut.valid_out.value}, expected: 0"
        
        assert dut.max_offset_weight == 8 * 32, \
            f"output max_offset_weight was incorrect on the {i}th cycle got: {dut.max_offset_weight}, expected: 256"
        
    return test_sync_offset

@cocotb.test()
async def test_uw_sync_derotate_ints_all(dut):
    for i in range(80):
        test_sync(dut, i)(dut)

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
    

