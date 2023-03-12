// This is meant to be a little adapter that
// can hold extra wiring logic so that our main
// design can conveniently be used inside a CUP
// (caravel_user_project), i.e. instantiated
// within user_project_wrapper, without mucking
// up use of the design also on an FPGA.
// Caravel needs this, because it doesn't allow
// extra logic to be synthesised in
// user_project_wrapper;
// it only allows wire assignments.

`default_nettype none
`timescale 1ns / 1ps

module solo_squash_caravel(
`ifdef USE_POWER_PINS
    inout vccd1,      // User area 1 1.8V supply
    inout vssd1,      // User area 1 digital ground
`endif
    // Wishbone Slave ports (WB MI A)
    input                       wb_clk_i,
    input                       wb_rst_i,
    // IOs
    input  [`MPRJ_IO_PADS-1:0]  io_in,
    output [`MPRJ_IO_PADS-1:0]  io_out,
    output [`MPRJ_IO_PADS-1:0]  io_oeb,
    // The following stuff is not (yet) needed for our design:
    // // MGMT SoC Wishbone Slave
    // input                       wbs_stb_i,
    // input                       wbs_cyc_i,
    // input                       wbs_we_i,
    // input [3:0]                 wbs_sel_i,
    // input [31:0]                wbs_dat_i,
    // input [31:0]                wbs_adr_i,
    // output                      wbs_ack_o,
    // output [31:0]               wbs_dat_o,
    // // Logic Analyzer Signals
    // input  [127:0]              la_data_in,
    // output [127:0]              la_data_out,
    // input  [127:0]              la_oenb,
    // // User maskable interrupt signals
    // output [2:0]                user_irq
);

    //NOTE: Our design avoids using IO[7:0] because mgmt core uses this.

    // Our design can be reset either by Wishbone reset or GPIO externally:
    wire reset = io_in[8] | wb_rst_i;

    solo_squash game(
`ifdef USE_POWER_PINS
        .vccd1      (vccd1),    // User area 1 1.8V power
        .vssd1      (vssd1),    // User area 1 digital ground
`endif
        // --- Inputs ---
        // Our design's main clock comes directly from Wishbone bus clock:
        .clk        (wb_clk_i),
        .reset      (reset),
        // Active-low buttons (pulled high by default):
        .pause_n    (io_in [ 9]),
        .new_game_n (io_in [10]),
        .down_key_n (io_in [11]),
        .up_key_n   (io_in [12]),

        // --- Outputs ---
        .hsync      (io_out[13]),
        .vsync      (io_out[14]),
        .red        (io_out[15]),
        .green      (io_out[16]),
        .blue       (io_out[17]),
        .speaker    (io_out[18]),

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
        // .la_data_in(la_data_in),
        // .la_data_out(la_data_out),
        // .la_oenb (la_oenb),
        // // IRQ
        // .irq(user_irq)
    );

    // Output enables are active-low.
    // During reset, we want them hi-Z,
    // so set corresponding io_oeb lines high.
    assign io_oeb[18:13] = {6{reset}};


endmodule
