import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, FallingEdge, ClockCycles
# import random

async def reset_solo_squash(dut):
    # Start off with reset (AH) asserted:
    dut.reset.value = 1
    # After 5 clocks, release reset:
    await ClockCycles(dut.clk, 5)
    dut.reset.value = 0

@cocotb.test()
async def test_solo_squash(dut):
    # Clock() args: signal, period, units ("step" is default).
    # Create a 25MHz clock (40ns period):
    clock = Clock(dut.clk, 40, units="ns")

    # Initial state:
    #SMELL: Is this right to do here?
    reset       = 0
    pause_n     = 1
    new_game_n  = 1
    up_key_n    = 1
    down_key_n  = 1
    #NOTE: Used to have dut.reset = 0, etc, but apparently this syntax is deprecated?

    cocotb.start_soon(clock.start())

    # 10 clock cycles:
    await ClockCycles(dut.clk, 10)

    # Reset:
    await reset_solo_squash(dut)

    # Give it another 10 clock cycles:
    await ClockCycles(dut.clk, 10)
    
    #### The stuff below is commented out because it's just an example of
    # some things we might want to do, to build a test...

    # # test a range of values
    # for i in range(10, 255, 20):
    #     # set pwm to this level
    #     dut.level.value = i

    #     await reset(dut)

    #     # wait pwm level clock steps
    #     for on in range(i):
    #         await RisingEdge(dut.clk)

    #         # assert high
    #         assert(dut.out)

    #     for off in range(255-i):
    #         await RisingEdge(dut.clk)

    #         # assert low
    #         assert(dut.out == 0)

    # ...AND WE'RE DONE!
