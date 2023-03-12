#NOTE: These tests are intended to be run against the main generic design,
# solo_squash.v. There's also solo_squash_caravel.v, but this is an adapter
# specifically for when we need to tweak a few signals to get the most out
# of using solo_squash.v in combination with the UPW (user_project_wrapper).

import cocotb
import os
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, FallingEdge, ClockCycles
# from cocotb.types import Logic
# import random

SIM_CLOCK_HZ = 25_000_000
SIM_CLOCK_PERIOD = 1_000_000_000 / SIM_CLOCK_HZ  # =40 (Clock period in nanoseconds)

async def reset_solo_squash(dut):
    # Initial input state:
    #SMELL: Is this right to do here?
    dut.reset.value       = 0
    dut.pause_n.value     = 1
    dut.new_game_n.value  = 1
    dut.up_key_n.value    = 1
    dut.down_key_n.value  = 1
    # Start off with reset (AH) asserted:
    dut.reset.value = 1
    # After 5 clocks, release reset:
    await ClockCycles(dut.clk, 5)
    dut.reset.value = 0

def design_clock(dut):
    return Clock(dut.clk, SIM_CLOCK_PERIOD, units="ns")

# Returns true if the given signal is driven as 0 or 1.
# Otherwise returns false (e.g. for logic X, Z, etc).
def known_driven(signal):
    return signal.value.binstr in {'0', '1'}

@cocotb.test()
async def test_reset(dut):
    clock = design_clock(dut)
    cocotb.start_soon(clock.start())
    # Get handles to signals:
    reset       = dut.reset
    pause_n     = dut.pause_n
    new_game_n  = dut.new_game_n
    up_key_n    = dut.up_key_n
    down_key_n  = dut.down_key_n
    red         = dut.red
    green       = dut.green
    blue        = dut.blue
    hsync       = dut.hsync
    vsync       = dut.vsync
    speaker     = dut.speaker
    # 10 clock cycles before reset (unknown state?)
    await ClockCycles(dut.clk, 10)
    await reset_solo_squash(dut)
    await RisingEdge(dut.clk)
    # Check for expected values and required stuff:
    assert known_driven(red)
    assert known_driven(green)
    assert known_driven(blue)
    assert known_driven(hsync)
    assert known_driven(vsync)
    assert known_driven(speaker)
    assert dut.hit == 0
    assert dut.h == 0
    assert dut.v == 0
    assert dut.inPaddle == 0
    assert dut.inBallX == 0
    assert dut.inBallY == 0
    # General sanity checks for paddle position (to make sure we also don't screw up our localparams):
    assert dut.paddle.value.integer == dut.PADDLE_RESET.value
    assert dut.paddle.value.integer >= dut.PADDLE_MIN.value
    assert dut.paddle.value.integer <= dut.PADDLE_MAX.value
    assert dut.paddle.value.integer >= 31
    assert dut.paddle.value.integer <= 480-31-dut.paddleSize.value
    # General sanity checks for ball starting position...
    #NOTE: ballX, ballY, and ballSize are double-pixel values:
    bx = dut.ballX.value.integer*2
    by = dut.ballY.value.integer*2
    bs = dut.ballSize.value*2 # parameter.
    assert bx == dut.BALLX_RESET.value*2
    assert by == dut.BALLY_RESET.value*2
    # Redundant, but just in case something is wrong with ball reset position,
    # make sure it is at least within the playfield area after a reset:
    assert bx >= 0
    assert bx <= dut.wallR_LIMIT.value-bs
    assert by >= 0
    assert by <= dut.wallB_LIMIT.value-bs


# For now, this test is really simple, and is just enough to capture a meaningful
# VCD from our design, at least 1 full frame worth, while making sure we have no X or Z outputs.
@cocotb.test()
async def test_generate_frames(dut):
    # Clock() args: signal, period, units ("step" is default).
    # Create a 25MHz clock (40ns period):
    clock = design_clock(dut)

    # Get handles to signals:
    reset       = dut.reset
    pause_n     = dut.pause_n
    new_game_n  = dut.new_game_n
    up_key_n    = dut.up_key_n
    down_key_n  = dut.down_key_n
    red         = dut.red
    green       = dut.green
    blue        = dut.blue
    hsync       = dut.hsync
    vsync       = dut.vsync
    speaker     = dut.speaker

    cocotb.start_soon(clock.start())

    # 10 clock cycles before reset (unknown state?)
    await ClockCycles(dut.clk, 10)

    # Reset:
    await reset_solo_squash(dut)

    # Now run for 2 full frames (which are 800x525, or 420,000 clocks each):
    frame_count = int(os.getenv('TEST_FRAMES') or 2)
    for frame in range(frame_count):
        print(f'Testing frame {frame+1} of {frame_count}...')
        for x in range(800):
            for y in range(525):
                # await ClockCycles(dut.clk, 1)
                await RisingEdge(dut.clk)
                # Ensure all outputs are driven:
                assert known_driven(red)
                assert known_driven(green)
                assert known_driven(blue)
                assert known_driven(hsync)
                assert known_driven(vsync)
                assert known_driven(speaker)
