`default_nettype none
`timescale 1ns / 1ps

// Wrapper for solo_squash module, targeting DE0-Nano board:
module solo_squash_de0nano(
  input           CLOCK_50, // Onboard 50MHz clock
  output  [7:0]   LED,      // 8 onboard LEDs
  input   [1:0]   KEY,      // 2 onboard pushbuttons
  input   [3:0]   SW,       // 4 onboard DIP switches
  inout   [33:0]  gpio1,    // GPIO1
  input   [1:0]   gpio1_IN  // GPIO1 input-only pins
);

//=======================================================
//  PARAMETER declarations
//=======================================================


//=======================================================
//  REG/WIRE declarations
//=======================================================

  // K4..K1 external buttons board (K4 is top, K1 is bottom):
  wire [4:1] K = {gpio1[23], gpio1[21], gpio1[19], gpio1[17]};

  // The KEY buttons are normally pulled high, but our design needs active-high:
  wire reset      = !KEY[0];
  wire new_game_n =  KEY[1];
  wire up_key_n   =  K[4];
  wire pause_n    =  K[3];
  wire down_key_n =  K[1];

  wire r;
  wire g;
  wire b;
  wire hsync;
  wire vsync;
  wire speaker;

//=======================================================
//  Structural coding
//=======================================================

  assign gpio1[0] = r;
  assign gpio1[1] = g;
  assign gpio1[3] = b;
    
  assign gpio1[5] = hsync;
  assign gpio1[7] = vsync;
  assign gpio1[9] = speaker;  // Sound the speaker on GPIO_19.
  assign LED[7]   = speaker;  // Also visualise speaker on LED7.

  //SMELL: This is a bad way to do clock dividing.
  // Can we instead use the built-in FPGA clock divider?
  reg clock_25; // VGA pixel clock of 25MHz is good enough. 25.175MHz is ideal (640x480x59.94)
  always @(posedge CLOCK_50) clock_25 <= ~clock_25;

  solo_squash game(
    // --- Inputs: ---
    .clk        (clock_25),
    .reset      (reset),

    .new_game_n (new_game_n),
    .pause_n    (pause_n),
    .up_key_n   (up_key_n),
    .down_key_n (down_key_n),
    
    // --- Outputs: ---
    .hsync      (hsync),
    .vsync      (vsync),
    .red        (r),
    .green      (g),
    .blue       (b),
    .speaker    (speaker)
  );

endmodule
