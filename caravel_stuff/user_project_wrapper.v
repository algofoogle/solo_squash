// SPDX-FileCopyrightText: 2020 Efabless Corporation
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

`default_nettype none
/*
 *-------------------------------------------------------------
 *
 * user_project_wrapper
 *
 * This wrapper enumerates all of the pins available to the
 * user for the user project.
 *
 * This example replaces user_proj_example with:
 * solo_squash_caravel, which in turn is wired up to
 * my design, solo_squash.
 *
 *-------------------------------------------------------------
 */

module user_project_wrapper #(
    parameter BITS = 32 //SMELL: Not used in this design?
) (
`ifdef USE_POWER_PINS
    inout vdda1,	// User area 1 3.3V supply
    inout vdda2,	// User area 2 3.3V supply
    inout vssa1,	// User area 1 analog ground
    inout vssa2,	// User area 2 analog ground
    inout vccd1,	// User area 1 1.8V supply
    inout vccd2,	// User area 2 1.8v supply
    inout vssd1,	// User area 1 digital ground
    inout vssd2,	// User area 2 digital ground
`endif

    // Wishbone Slave ports (WB MI A)
    input wb_clk_i,
    input wb_rst_i,
    input wbs_stb_i,
    input wbs_cyc_i,
    input wbs_we_i,
    input [3:0] wbs_sel_i,
    input [31:0] wbs_dat_i,
    input [31:0] wbs_adr_i,
    output wbs_ack_o,
    output [31:0] wbs_dat_o,

    // Logic Analyzer Signals
    input  [127:0] la_data_in,
    output [127:0] la_data_out,
    input  [127:0] la_oenb,

    // IOs
    input  [`MPRJ_IO_PADS-1:0] io_in,
    output [`MPRJ_IO_PADS-1:0] io_out,
    output [`MPRJ_IO_PADS-1:0] io_oeb,

    // Analog (direct connection to GPIO pad---use with caution)
    // Note that analog I/O is not available on the 7 lowest-numbered
    // GPIO pads, and so the analog_io indexing is offset from the
    // GPIO indexing by 7 (also upper 2 GPIOs do not have analog_io).
    inout [`MPRJ_IO_PADS-10:0] analog_io,

    // Independent clock (on independent integer divider)
    input   user_clock2,

    // User maskable interrupt signals
    output [2:0] user_irq
);

/*--------------------------------------*/
/* User project is instantiated  here   */
/*--------------------------------------*/

    // solo_squash_caravel is a wrapper around my generic solo_squash design.
    // It has a tiny bit of extra logic in it that makes the generic design
    // suitable for use inside Caravel i.e. it is like an adapter, in the
    // same way that we'd adapt the design for an FPGA or CPLD. That logic
    // is not allowed in (i.e. cannot be synthesised in) this UPW.
    // Compare this file with solo_squash_caravel.v:
    //  https://github.com/algofoogle/solo_squash/blob/main/src/solo_squash_caravel.v
    // ...and solo_squash.v:
    //  https://github.com/algofoogle/solo_squash/blob/main/src/solo_squash.v
    //NOTE: I've renamed this instance from "mprj" to "adapter" mostly as
    // an exercise in showing that it doesn't have to keep the "mprj" name
    // so long as we update openlane/user_project_wrapper/config.json:FP_PDN_MACRO_HOOKS.
    // In this case, "adapter" refers to the fact that this specific module just
    // adapts the otherwise generic "solo_squash" design to the specific IOs
    // of Caravel, including a tiny bit of glue logic and debug stuff that
    // normally would be absent/different if we were adapting it to (say) an FPGA board.
    // From our TB, the full chain to our design now ends up being:
    // solo_squash_caravel_tb.uut.mprj.adapter.game
    solo_squash_caravel adapter (
    `ifdef USE_POWER_PINS
        .vccd1(vccd1),	// User area 1 1.8V power
        .vssd1(vssd1),	// User area 1 digital ground
    `endif
        // Internal inputs:
        .wb_clk_i           (wb_clk_i),
        .wb_rst_i           (wb_rst_i),
        // External inputs:
        .ext_reset_n        (io_in [ 8]),
        .pause_n            (io_in [ 9]),
        .new_game_n         (io_in [10]),
        .down_key_n         (io_in [11]),
        .up_key_n           (io_in [12]),
        // Outputs:
        .red                (io_out[13]),
        .green              (io_out[14]),
        .blue               (io_out[15]),
        .hsync              (io_out[16]),
        .vsync              (io_out[17]),
        .speaker            (io_out[18]),
        .design_oeb         (io_oeb[18:13]),
        // Debug:
        .gpio_ready         (la_data_in[32]), // Input from LA controlled by VexRiscv.
        .debug_design_reset (io_out[19]),
        .debug_gpio_ready   (io_out[20]), // Loopback output of gpio_ready input.
        .debug_oeb          (io_oeb[20:19])

        // The following stuff is not (yet) needed for our design:
        // // MGMT SoC Wishbone Slave
        // .wbs_cyc_i(wbs_cyc_i),
        // .wbs_stb_i(wbs_stb_i),
        // .wbs_we_i(wbs_we_i),
        // .wbs_sel_i(wbs_sel_i),
        // .wbs_adr_i(wbs_adr_i),
        // .wbs_dat_i(wbs_dat_i),
        // .wbs_ack_o(wbs_ack_o),
        // .wbs_dat_o(wbs_dat_o),
        // // Logic Analyzer
        // .la_data_in (la_data_in),
        // .la_data_out(la_data_out),
        // .la_oenb (la_oenb),
        // // IRQ
        // .irq(user_irq),
    );

endmodule	// user_project_wrapper

`default_nettype wire
