#NOTE: This is a copy of the same tests from the solo_squash repo
# https://github.com/algofoogle/solo_squash/blob/main/test/test_solo_squash.py
# and it has been modified a little to work within Caravel.
# Hierarchically, I think we'd have:
#   User code:      solo_squash_tb
#   Caravel code:   -> uut (caravel) -> mprj (user_project_wrapper)
#   User code:      -> mprj (solo_squash_caravel) -> game (solo_squash)
# Note that solo_squash_tb includes a few extra wire definitions that assign
# names to the Caravel GPIOs (etc) that we've chosen to use, hence meaning
# that most of the code from the original tests can still use those names
# for convenience.

import cocotb
import os
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, FallingEdge, ClockCycles


SIM_CLOCK_HZ = 25_000_000
SIM_CLOCK_PERIOD = 1_000_000_000 / SIM_CLOCK_HZ  # =40 (Clock period in nanoseconds)


def design_clock(dut):
    return Clock(dut.clk, SIM_CLOCK_PERIOD, units="ns")


##############################################################################
### INITIAL TEST: test_start
### Goes thru reset and brings up power rails of Caravel.
##############################################################################
@cocotb.test()
async def test_start(dut):
    # Init and start the main Caravel clock at 25MHz:
    clock = design_clock(dut)
    cocotb.start_soon(clock.start())

    # Assert Caravel reset (RSTB):
    dut.RSTB.value = 0
    # For now, make sure our external reset is NOT asserted:
    dut.ext_reset_n.value = 1
    # Start with all power rails off:
    dut.power1.value = 0
    dut.power2.value = 0
    dut.power3.value = 0
    dut.power4.value = 0

    # Bring up each of the power rails gradually, 8 clocks (320ns) apart:
    await ClockCycles(dut.clk, 8);      dut.power1.value = 1
    await ClockCycles(dut.clk, 8);      dut.power2.value = 1
    await ClockCycles(dut.clk, 8);      dut.power3.value = 1
    await ClockCycles(dut.clk, 8);      dut.power4.value = 1

    # Wait another 80 clock cycles (3.2us; does it need to be this much?)
    # and then release reset:
    await ClockCycles(dut.clk, 80);     dut.RSTB.value = 1

    #SMELL: I think that only NOW, since RSTB is released, the
    # VexRiscv firmware should start executing.
    # So, should we now wait until the firmware has finished executing,
    # GPIOs are ready, and outputs are live? If so, should we then
    # do a design-level reset (i.e. pulse dut.ext_reset_n to 0 then 1)?

    # Wait for GPIOs to become active
    # (which comes from uut.housekeeping.serial_load):
    await RisingEdge(dut.gpio_ready)

    # Wait 5 clock cycles:
    await ClockCycles(dut.clk, 5)

    # Then assert our external reset for 10 clock cycles,
    # so we know where we'll end up:
    dut.ext_reset_n.value = 0
    await ClockCycles(dut.clk, 10);     dut.ext_reset_n.value = 1

    # Now we should be able to await 420,001 clock cycles and prove
    # that a full frame (plus 1 clock) completes:


    #SMELL: For the real world, we should consider making our firmware
    # use an LA line to reset the design once GPIO setup is complete,
    # or not worry about it at all (since it will generate a display
    # in good time anyway) or we could even: (a) supply the serial_load
    # into our design, and let it self-reset; or (b) just use a timed
    # external reset or leave that reset up to the user via pushbutton.

    #CHEAT: Just wait out (say) 500us and then assume GPIOs are ready,
    # assert ext_reset_n, release, then carry on.
    #NOTE: It might be possible to detect GPIO setup complete (and our
    # outputs activated) by checking:
    # solo_squash_tb.uut.padframe.mprj_pads.oeb[37:0]
    # ...and looking for oeb[13] (say) going from Z to 0. These seem
    # to change all coincidently with outputs going from Z to asserted.

    # For now, I'll just let 500,000 clock ticks elapse (i.e. enough for
    # GPIOs to be set up, and at least 1 full frame to render):
    await ClockCycles(dut.clk, 420_001)



# async def reset_solo_squash(dut):
#     # Initial input state:
#     #SMELL: Is this right to do here?
#     dut.reset.value       = 0
#     dut.pause_n.value     = 1
#     dut.new_game_n.value  = 1
#     dut.up_key_n.value    = 1
#     dut.down_key_n.value  = 1
#     # Start off with reset (AH) asserted:
#     dut.reset.value = 1
#     # After 5 clocks, release reset:
#     await ClockCycles(dut.clk, 5)
#     dut.reset.value = 0


# # Returns true if the given signal is driven as 0 or 1.
# # Otherwise returns false (e.g. for logic X, Z, etc).
# def known_driven(signal):
#     return signal.value.binstr in {'0', '1'}


# @cocotb.test()
# async def test_reset(dut):
#     clock = design_clock(dut)
#     cocotb.start_soon(clock.start())
#     # Get handles to signals:
#     reset       = dut.reset
#     pause_n     = dut.pause_n
#     new_game_n  = dut.new_game_n
#     up_key_n    = dut.up_key_n
#     down_key_n  = dut.down_key_n
#     red         = dut.red
#     green       = dut.green
#     blue        = dut.blue
#     hsync       = dut.hsync
#     vsync       = dut.vsync
#     speaker     = dut.speaker
#     # 10 clock cycles before reset (unknown state?)
#     await ClockCycles(dut.clk, 10)
#     await reset_solo_squash(dut)
#     await RisingEdge(dut.clk)
#     # Check for expected values and required stuff:
#     assert known_driven(red)
#     assert known_driven(green)
#     assert known_driven(blue)
#     assert known_driven(hsync)
#     assert known_driven(vsync)
#     assert known_driven(speaker)
#     assert dut.hit == 0
#     assert dut.h == 0
#     assert dut.v == 0
#     assert dut.inPaddle == 0
#     assert dut.inBallX == 0
#     assert dut.inBallY == 0
#     # General sanity checks for paddle position (to make sure we also don't screw up our localparams):
#     assert dut.paddle.value.integer == dut.PADDLE_RESET.value
#     assert dut.paddle.value.integer >= dut.PADDLE_MIN.value
#     assert dut.paddle.value.integer <= dut.PADDLE_MAX.value
#     assert dut.paddle.value.integer >= 31
#     assert dut.paddle.value.integer <= 480-31-dut.paddleSize.value
#     # General sanity checks for ball starting position...
#     #NOTE: ballX, ballY, and ballSize are double-pixel values:
#     bx = dut.ballX.value.integer*2
#     by = dut.ballY.value.integer*2
#     bs = dut.ballSize.value*2 # parameter.
#     assert bx == dut.BALLX_RESET.value*2
#     assert by == dut.BALLY_RESET.value*2
#     # Redundant, but just in case something is wrong with ball reset position,
#     # make sure it is at least within the playfield area after a reset:
#     assert bx >= 0
#     assert bx <= dut.wallR_LIMIT.value-bs
#     assert by >= 0
#     assert by <= dut.wallB_LIMIT.value-bs


# # For now, this test is really simple, and is just enough to capture a meaningful
# # VCD from our design, at least 1 full frame worth, while making sure we have no X or Z outputs.
# @cocotb.test()
# async def test_generate_frames(dut):
#     # Clock() args: signal, period, units ("step" is default).
#     # Create a 25MHz clock (40ns period):
#     clock = design_clock(dut)

#     # Get handles to signals:
#     reset       = dut.reset
#     pause_n     = dut.pause_n
#     new_game_n  = dut.new_game_n
#     up_key_n    = dut.up_key_n
#     down_key_n  = dut.down_key_n
#     red         = dut.red
#     green       = dut.green
#     blue        = dut.blue
#     hsync       = dut.hsync
#     vsync       = dut.vsync
#     speaker     = dut.speaker

#     cocotb.start_soon(clock.start())

#     # 10 clock cycles before reset (unknown state?)
#     await ClockCycles(dut.clk, 10)

#     # Reset:
#     await reset_solo_squash(dut)

#     # Now run for 2 full frames (which are 800x525, or 420,000 clocks each):
#     frame_count = int(os.getenv('TEST_FRAMES') or 2)
#     for frame in range(frame_count):
#         print(f'Testing frame {frame+1} of {frame_count}...')
#         for x in range(800):
#             for y in range(525):
#                 # await ClockCycles(dut.clk, 1)
#                 await RisingEdge(dut.clk)
#                 # Ensure all outputs are driven:
#                 assert known_driven(red)
#                 assert known_driven(green)
#                 assert known_driven(blue)
#                 assert known_driven(hsync)
#                 assert known_driven(vsync)
#                 assert known_driven(speaker)
