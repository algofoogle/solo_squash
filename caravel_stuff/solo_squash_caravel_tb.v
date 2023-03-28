// SPDX-FileCopyrightText: 2023 Anton Maurovic <anton@maurovic.com>
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
// SPDX-License-Identifier: Apache-2.0


// This is Anton's testbench for solo_squash_caravel.
// It does basic driving and VCD capture.

`default_nettype none

`timescale 1 ns / 1 ps

module solo_squash_caravel_tb;

    integer clock_count_1k = 0; // Used just to report how many clock ticks we've done.
    initial begin
        // Show configured default state of GPIOs (based on verilog/rtl/user_defines.v).
        // Note that these might not take effect unless your test runner (see Makefile)
        // is actually explicitly including verilog/rtl/user_defines.v before other files.
        $display ("USER_CONFIG_GPIO_5_INIT  = %x (%b)", `USER_CONFIG_GPIO_5_INIT,  `USER_CONFIG_GPIO_5_INIT);
        $display ("USER_CONFIG_GPIO_6_INIT  = %x (%b)", `USER_CONFIG_GPIO_6_INIT,  `USER_CONFIG_GPIO_6_INIT);
        $display ("USER_CONFIG_GPIO_7_INIT  = %x (%b)", `USER_CONFIG_GPIO_7_INIT,  `USER_CONFIG_GPIO_7_INIT);
        $display ("USER_CONFIG_GPIO_8_INIT  = %x (%b)", `USER_CONFIG_GPIO_8_INIT,  `USER_CONFIG_GPIO_8_INIT);
        $display ("USER_CONFIG_GPIO_9_INIT  = %x (%b)", `USER_CONFIG_GPIO_9_INIT,  `USER_CONFIG_GPIO_9_INIT);
        $display ("USER_CONFIG_GPIO_10_INIT = %x (%b)", `USER_CONFIG_GPIO_10_INIT, `USER_CONFIG_GPIO_10_INIT);
        $display ("USER_CONFIG_GPIO_11_INIT = %x (%b)", `USER_CONFIG_GPIO_11_INIT, `USER_CONFIG_GPIO_11_INIT);
        $display ("USER_CONFIG_GPIO_12_INIT = %x (%b)", `USER_CONFIG_GPIO_12_INIT, `USER_CONFIG_GPIO_12_INIT);
        $display ("USER_CONFIG_GPIO_13_INIT = %x (%b)", `USER_CONFIG_GPIO_13_INIT, `USER_CONFIG_GPIO_13_INIT);
        $display ("USER_CONFIG_GPIO_14_INIT = %x (%b)", `USER_CONFIG_GPIO_14_INIT, `USER_CONFIG_GPIO_14_INIT);
        $display ("USER_CONFIG_GPIO_15_INIT = %x (%b)", `USER_CONFIG_GPIO_15_INIT, `USER_CONFIG_GPIO_15_INIT);
        $display ("USER_CONFIG_GPIO_16_INIT = %x (%b)", `USER_CONFIG_GPIO_16_INIT, `USER_CONFIG_GPIO_16_INIT);
        $display ("USER_CONFIG_GPIO_17_INIT = %x (%b)", `USER_CONFIG_GPIO_17_INIT, `USER_CONFIG_GPIO_17_INIT);
        $display ("USER_CONFIG_GPIO_18_INIT = %x (%b)", `USER_CONFIG_GPIO_18_INIT, `USER_CONFIG_GPIO_18_INIT);
        $display ("USER_CONFIG_GPIO_19_INIT = %x (%b)", `USER_CONFIG_GPIO_19_INIT, `USER_CONFIG_GPIO_19_INIT);
        $display ("USER_CONFIG_GPIO_20_INIT = %x (%b)", `USER_CONFIG_GPIO_20_INIT, `USER_CONFIG_GPIO_20_INIT);
        $display ("USER_CONFIG_GPIO_21_INIT = %x (%b)", `USER_CONFIG_GPIO_21_INIT, `USER_CONFIG_GPIO_21_INIT);
        
        // Dump running state of all signals to solo_squash_caravel.vcd:
        $dumpfile ("solo_squash_caravel.vcd");
        $dumpvars (0, solo_squash_caravel_tb);

        // Monitor for a large number of clock cycles while the tests run in parallel,
        // reporting for each 1,000 that occur to show progress.
        //NOTE: cocotb tests should do the equivalent of a $finish before this loop
        // finishes. If not, we'll get the error seen below the loop.
        repeat (1000) begin // 1000 batches...
            repeat (1000) @(posedge clk); // ...of 1000 cycles.
            ++clock_count_1k;
            $display("%dk clock cycles", clock_count_1k);
        end
        $display("%c[0;31m",27); // ANSI escape for red text.
        $display("solo_squash_caravel_tb: The main test monitor loop finished before the actual tests did.");
        $display("solo_squash_caravel_tb: Increase the monitor loop cycles, or check the tests are actually working.");
        $display("%c[0m",27); // ANSI escape for default text.
    end

    // These connect up with uut:
    reg clk;
    reg RSTB;
    reg power1, power2;
    reg power3, power4;
    wire gpio;
    wire [37:0] mprj_io;
    wire flash_csb;
    wire flash_clk;
    wire flash_io0;
    wire flash_io1;

    // Caravel power lines:
    wire VDD3V3         = power1;
    wire VDD1V8         = power2;
    wire USER_VDD3V3    = power3;
    wire USER_VDD1V8    = power4;
    wire VSS = 1'b0;
    //NOTE: Power lines are a little different in MPW8+ ??
    // See: https://github.com/efabless/caravel_user_project/blob/bc4ccfec4b35d19220740f143ff1798fdfa4f0eb/verilog/dv/io_ports/io_ports_tb.v#L218-L244

    // These are convenience signal names for our GPIOs,
    // that allow our stand-alone solo_squash cocotb tests to be reused...
    // Inputs (that come from our cocotb tests):
    wire ext_reset_n;
    wire pause_n;
    wire new_game_n;
    wire up_key_n;
    wire down_key_n;
    assign mprj_io[ 8]  = ext_reset_n;
    assign mprj_io[ 9]  = pause_n;
    assign mprj_io[10]  = new_game_n;
    assign mprj_io[11]  = up_key_n;
    assign mprj_io[12]  = down_key_n;
    // Outputs (that our cocotb tests read):
    wire red            = mprj_io[13];
    wire green          = mprj_io[14];
    wire blue           = mprj_io[15];
    wire hsync          = mprj_io[16];
    wire vsync          = mprj_io[17];
    wire speaker        = mprj_io[18];
    // The following signals are intended just for testing...
    // The actual internal reset signal that our design receives
    // (generated from `wb_rst_i|~IO[8]` because ext_reset_n is
    // active-low, being driven by a pulled-up pushbutton typically):
    //SMELL: ext_reset_n could be indeterminate before GPIOs are initialised!
    wire design_reset   = mprj_io[19];
    // This signal will pulse high when GPIOs get loaded/activated:
    wire gpio_ready     = mprj_io[20];

    caravel uut (
        .vddio    (VDD3V3),
        .vssio    (VSS),
        .vdda     (VDD3V3),
        .vssa     (VSS),
        .vccd     (VDD1V8),
        .vssd     (VSS),
        .vdda1    (USER_VDD3V3),
        .vdda2    (USER_VDD3V3),
        .vssa1    (VSS),
        .vssa2    (VSS),
        .vccd1    (USER_VDD1V8),
        .vccd2    (USER_VDD1V8),
        .vssd1    (VSS),
        .vssd2    (VSS),
        .clock    (clk),
        .gpio     (gpio),
        .mprj_io  (mprj_io),
        .flash_csb(flash_csb),
        .flash_clk(flash_clk),
        .flash_io0(flash_io0),
        .flash_io1(flash_io1),
        .resetb   (RSTB)
    );

    spiflash #(
        .FILENAME("solo_squash_caravel.hex")
    ) spiflash (
        .csb(flash_csb),
        .clk(flash_clk),
        .io0(flash_io0),
        .io1(flash_io1),
        .io2(),         // not used
        .io3()          // not used
    );

endmodule
`default_nettype wire