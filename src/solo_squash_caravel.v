`default_nettype none
`timescale 1ns / 1ps
module solo_squash_caravel (
`ifdef USE_POWER_PINS
    inout vccd1,
    inout vssd1,
`endif
    input           wb_clk_i,
    input           wb_rst_i,
    input           gpio_ready,
    input           ext_reset_n,
    input           pause_n,
    input           new_game_n,
    input           down_key_n,
    input           up_key_n,
    output          red,
    output          green,
    output          blue,
    output          hsync,
    output          vsync,
    output          speaker,
    output          debug_design_reset,
    output          debug_gpio_ready,
    output [5:0]    design_oeb,
    output [1:0]    debug_oeb 
);
    wire design_reset = wb_rst_i | ~ext_reset_n;
    assign design_oeb = {6{design_reset}};
    assign debug_oeb = 2'b00;
    assign debug_design_reset = design_reset;
    assign debug_gpio_ready = gpio_ready;
    solo_squash game(
`ifdef USE_POWER_PINS
        .vccd1      (vccd1),
        .vssd1      (vssd1),
`endif
        .clk        (wb_clk_i),
        .reset      (design_reset),
        .pause_n    (pause_n),
        .new_game_n (new_game_n),
        .down_key_n (down_key_n),
        .up_key_n   (up_key_n),
        .red        (red),
        .green      (green),
        .blue       (blue),
        .hsync      (hsync),
        .vsync      (vsync),
        .speaker    (speaker)
    );
endmodule
