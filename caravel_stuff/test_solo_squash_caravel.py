# SPDX-FileCopyrightText: 2023 Anton Maurovic <anton@maurovic.com>
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# SPDX-License-Identifier: Apache-2.0


#NOTE: This is a copy of the same tests from the solo_squash repo
# https://github.com/algofoogle/solo_squash/blob/main/test/test_solo_squash.py
# and it has been modified a little to work within Caravel.
# Hierarchically, I think we'd have:
#   User code:      solo_squash_caravel_tb
#   Caravel code:   -> uut (caravel) -> mprj (user_project_wrapper)
#   User code:      -> adapter (solo_squash_caravel) -> game (solo_squash)
# Note that solo_squash_tb includes a few extra wire definitions that assign
# names to the Caravel GPIOs (etc) that we've chosen to use, hence meaning
# that most of the code from the original tests can still use those names
# for convenience.

import cocotb
import os
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, FallingEdge, ClockCycles, Timer, with_timeout
from cocotb.types import Logic


SIM_CLOCK_HZ = 25_000_000
SIM_CLOCK_PERIOD = 1_000_000_000 / SIM_CLOCK_HZ  # =40 (Clock period in nanoseconds)

def init_design_clock(dut):
    clock = Clock(dut.clk, SIM_CLOCK_PERIOD, units="ns")
    cocotb.start_soon(clock.start())
    return clock

async def settle_step(dut):
    # Wait an arbitrarily small amount of time for logic to settle:
    await Timer(10, units="ns")
    # await Timer(1, units="step")

# Assert our external reset for 10 clock cycles,
# so we will then make it to a known state:
async def external_reset_cycle(dut):
    dut.ext_reset_n.value = 0
    await ClockCycles(dut.clk, 10)
    dut.ext_reset_n.value = 1
    await settle_step(dut)
    #SMELL: For the real world, we could consider making our firmware
    # use an LA line to reset the design once GPIO setup is complete,
    # or not worry about it at all (since it will generate a display
    # in good time anyway) or we could even: (a) supply the serial_load
    # into our design, and let it self-reset; or (b) just use a timed
    # external reset or leave that reset up to the user via pushbutton.


# Returns true if the given signal is driven as 0 or 1.
# Otherwise returns false (e.g. for logic X, Z, etc).
def known_driven(signal):
    return signal.value.binstr in {'0', '1'}

# Returns true if the given signal is hi-Z:
def z(signal):
    return signal.value.binstr == 'z'


##############################################################################
### INITIAL TEST: test_start:
### Goes thru reset and brings up power rails of Caravel.
### NOTE: I'm assuming that if this test is run first, then at the end the
### whole system is in a ready state for GPIO and further tests.
##############################################################################
@cocotb.test()
async def test_start(dut):
    # Init and start the main Caravel clock at 25MHz:
    clock = init_design_clock(dut)
    print("--- TEST DEBUG: Clock started")

    # Assert Caravel reset (RSTB):
    dut.RSTB.value = 0
    # For now, make sure our external reset is NOT asserted:
    dut.ext_reset_n.value   = 1
    dut.up_key_n.value      = 1 # Logic('z')
    dut.down_key_n.value    = 1 # Logic('z')
    dut.new_game_n.value    = 1 # Logic('z')
    dut.pause_n.value       = 1 # Logic('z')
    # Start with all power rails off:
    dut.power1.value = 0
    dut.power2.value = 0
    dut.power3.value = 0
    dut.power4.value = 0
    print("--- TEST DEBUG: Initial state set")

    # Bring up each of the power rails gradually, 8 clocks (320ns) apart:
    await ClockCycles(dut.clk, 8);      dut.power1.value = 1
    await ClockCycles(dut.clk, 8);      dut.power2.value = 1
    await ClockCycles(dut.clk, 8);      dut.power3.value = 1
    await ClockCycles(dut.clk, 8);      dut.power4.value = 1
    print("--- TEST DEBUG: Power bringup complete")

    # Wait another 80 clock cycles and then release reset
    # (3.2us; does it need to be this much? Maybe this reflects a real RC reset delay)
    await ClockCycles(dut.clk, 80);     dut.RSTB.value = 1
    print("--- TEST DEBUG: Reset 1 released")

    # Wait 500 clock cycles, then assert reset again:
    await ClockCycles(dut.clk, 500);      dut.RSTB.value = 0
    print("--- TEST DEBUG: Reset 2 asserted")
    # Release reset after another 500 clock cycles:
    await ClockCycles(dut.clk, 500);      dut.RSTB.value = 1
    print("--- TEST DEBUG: Reset 2 released")

    # Wait for GPIOs to become active
    # (when our firmware signals it via loopback from pulse on LA[32]):
    await with_timeout(RisingEdge(dut.gpio_ready), 1000, 'us')
    await with_timeout(FallingEdge(dut.gpio_ready), 200, 'us')
    print("--- TEST DEBUG: GPIOs are ready")

    # Wait 100 clock cycles (arbitrary);
    # let design run freely before we'll reset it.
    await ClockCycles(dut.clk, 100)

    # Assert our external reset for 10 clock cycles,
    # so we will then make it to a known state for remaining tests:
    print("--- TEST DEBUG: Resetting main design...")
    await external_reset_cycle(dut)
    print("--- TEST DEBUG: ...main reset done")
    # At this point, the design is at its initial post-reset state,
    # so other tests are good to go.
    assert dut.gpio_ready.value == 0 # This was only _pulsed_ (above) so it should now be 0.
    assert dut.design_reset.value == 0 # Design should not be in reset now.
    # Typical outputs should all be asserted 0 or 1:
    assert known_driven(dut.hsync)
    assert known_driven(dut.vsync)
    assert known_driven(dut.red)
    assert known_driven(dut.green)
    assert known_driven(dut.blue)
    assert known_driven(dut.speaker)
    # Await 1 full clock, to balance out settle_step from external_reset_cycle:
    await ClockCycles(dut.clk, 1)
    print("--- TEST DEBUG: Ready for other tests")



##############################################################################
### test_external_reset:
### Make sure we get expected behaviour when an external reset is asserted
### and then released
##############################################################################
@cocotb.test()
async def test_external_reset(dut):
    # Even though each test seems to pick up with the state of where the last
    # one left off, it seems we need to create and start a clock at the start
    # of each of these tests or the clock will otherwise just be stalled
    # and the test will just keep VCD-logging that stalled state endlessly.
    clock = init_design_clock(dut)
    print("--- TEST DEBUG: Clock started in test_external_reset")

    # Await 50 clocks, then prove there is still meaningful output:
    await ClockCycles(dut.clk, 50)
    print("--- TEST DEBUG: 50 clocks elapsed")
    assert dut.gpio_ready.value == 0 # This was only _pulsed_ so it should now be 0.
    assert dut.design_reset.value == 0 # Design should not be in reset now.
    # Typical outputs should all be asserted 0 or 1:
    assert known_driven(dut.hsync)
    assert known_driven(dut.vsync)
    assert known_driven(dut.red)
    assert known_driven(dut.green)
    assert known_driven(dut.blue)
    assert known_driven(dut.speaker)
    print("--- TEST DEBUG: Outputs OK")

    # Now assert external reset:
    dut.ext_reset_n.value = 0
    await settle_step(dut)
    # await settle_step(dut)
    #SMELL: Do we need to let the clock tick once here,
    # or otherwise await a tiny delay (maybe a half-clock)?
    # This might be necessary to expose possible GL issues later?
    # Make sure it disabled regular outputs:
    assert z(dut.hsync)
    assert z(dut.vsync)
    assert z(dut.red)
    assert z(dut.green)
    assert z(dut.blue)
    assert z(dut.speaker)
    # Make sure design_reset is NOT a disabled output, and is also now asserted:
    assert dut.design_reset.value == 1
    # Make sure gpio_ready is NOT disabled, and remains outputting 0:
    assert dut.gpio_ready == 0
    print("--- TEST DEBUG: Reset activated; outputs OK")

    # Keep reset asserted for 10 clocks, then release and check again:
    await ClockCycles(dut.clk, 10)
    dut.ext_reset_n.value = 1 # Release external reset.
    await settle_step(dut)
    print("--- TEST DEBUG: Reset released")
    assert known_driven(dut.hsync)
    assert known_driven(dut.vsync)
    assert known_driven(dut.red)
    assert known_driven(dut.green)
    assert known_driven(dut.blue)
    assert known_driven(dut.speaker)
    assert dut.design_reset.value == 0
    assert dut.gpio_ready == 0
    print("--- TEST DEBUG: Outputs OK")
    # Clock sync:
    await ClockCycles(dut.clk, 1)


##############################################################################
### test_frame0:
### Generate the first full frame after issuing a reset.
### At the moment this doesn't assert any tests, but rather just ensures
### we capture a good continuation of the VCD to examine.
##############################################################################
@cocotb.test()
async def test_frame0(dut):
    clock = init_design_clock(dut)
    print("--- TEST DEBUG: Clock started in test_frame0")

    await external_reset_cycle(dut)
    print("--- TEST DEBUG: Reset completed. Rendering first frame...")

    # Now we should be able to await 420,001 clock cycles and prove
    # that a full frame (plus 1 clock) completes:
    await ClockCycles(dut.clk, 420_001)
    print("--- TEST DEBUG: First frame completed")

