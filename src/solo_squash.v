















`default_nettype none
`timescale 1ns / 1ps








module solo_squash #(
  parameter HRES        = 640,
  parameter HF          = 16,
  parameter HS          = 96,
  parameter HB          = 48,
  parameter VRES        = 480,
  parameter VF          = 10,
  parameter VS          = 2,
  parameter VB          = 33,
  parameter paddleSize  = 64,
  parameter ballSize    = 8,
  parameter wallWidth   = 32
)(
`ifdef USE_POWER_PINS
  inout vccd1,
  inout vssd1,
`endif

  input clk,




  input reset,






	input pause_n,
  input new_game_n,
  input down_key_n,
  input up_key_n,
  output hsync,
  output vsync,
  output speaker,
  output red,
  output green,
  output blue
);
  localparam HFULL        = HRES+HF+HS+HB;
  localparam VFULL        = VRES+VF+VS+VB;
  localparam BALLX_RESET  = (wallWidth+32)>>1;
  localparam BALLY_RESET  = (wallWidth+32)>>1;
  localparam PADDLE_RESET = wallWidth+32;
  localparam PADDLE_MIN   = wallWidth;
  localparam PADDLE_MAX   = VRES-wallWidth-paddleSize;
  localparam wallL_LIMIT  =       wallWidth;
  localparam wallR_LIMIT  = HRES -wallWidth;
  localparam wallT_LIMIT  =       wallWidth;
  localparam wallB_LIMIT  = VRES -wallWidth;









  reg [9:0]   h;
  reg [9:0]   v;
  reg         inPaddle;
  reg         inBallX;
  reg         inBallY;
  reg         ballDirX;
  reg         ballDirY;
  reg         hit;
  reg [8:0]   paddle;
  reg [8:0]   ballX;
  reg [7:0]   ballY;


  wire hmax     = h == (HFULL-1);
  wire vmax     = v == (VFULL-1);

  wire wallT    = v <  wallT_LIMIT;
  wire wallB    = v >= wallB_LIMIT;
  wire wallL    = h <  wallL_LIMIT;
  wire wallR    = h >= wallR_LIMIT;


  wire visible  = h < HRES && v < VRES;

  wire up       = ~up_key_n;
  wire down     = ~down_key_n;

  always @(posedge clk) begin




    if (reset)

    begin
      
      hit       <= 0;
      paddle    <= PADDLE_RESET;
      ballX     <= BALLX_RESET; 
      ballY     <= BALLY_RESET;
      
      h         <= 0;
      v         <= 0;
      inPaddle  <= 0;
      inBallX   <= 0;
      inBallY   <= 0;
      ballDirX  <= 1;
      ballDirY  <= 1;

      
      
      offset    <= 0;

    end else begin

      if (0==new_game_n) begin




        hit       <= 0;
        paddle    <= PADDLE_RESET;
        ballX     <= BALLX_RESET; 
        ballY     <= BALLY_RESET;


      end


      h <= hmax ? 10'b0 : h+1'b1;


      inBallX <= (inBallX ? h[9:1]!=ballX+ballSize : h[9:1]==ballX) & (ballX[8:3]<=6'b100101); //(ballX<=296);



      if (inBallX && inBallY & inPaddle && wallL) begin

        ballDirX <= 1;





        hit <= 1;
      end

      else if (inBallX && wallR) ballDirX <= 0;


            if (inBallY && wallB) ballDirY <= 0;
      else  if (inBallY && wallT) ballDirY <= 1;





      if (hmax) begin

        v <= vmax ? 10'b0 : v+1'b1;


        if (v[8:0]==paddle) begin

          inPaddle <= 1;






          hit <= 0;
        end
        else if (v==paddle+paddleSize) inPaddle <= 0;


        inBallY <= inBallY ? v[9:1]!=ballY+ballSize : v[8:1]==ballY;


        if (vmax && 1==pause_n) begin


          offset <= offset + 1;








                if (down  && paddle <  PADDLE_MAX) paddle <= paddle+9'd2;
          else  if (up    && paddle >= PADDLE_MIN) paddle <= paddle-9'd2;




          ballX <= ballDirX ? ballX+9'd3 : ballX-9'd3;
          ballY <= ballDirY ? ballY+8'd3 : ballY-8'd3;


        end
      end
    end
  end

  assign hsync = ~((HRES+HF) <= h && h < (HRES+HF+HS));
  assign vsync = ~((VRES+VF) <= v && v < (VRES+VF+VS));


  assign speaker =
    (v[5] & hit) |
    (v[6] & (ballX>=((wallR_LIMIT>>1)-ballSize) | ballY<(wallL_LIMIT>>1) | ballY>=(wallB_LIMIT>>1)-ballSize));




  assign green = visible & (
    wallT | wallB | wallR |
    (inBallX & inBallY)
  );
	


	wire [4:0] v1 = v[4:0]-2;
	wire [4:0] h1 = h[4:0]-2;
	
  assign red = visible & (
    ((wallT | wallB | wallR) & (&v1[4:2] | &h1[4:2])) |
    (wallL & inPaddle)
  );




  reg [4:0] offset;
  wire [9:0] oh = h - offset[4:1];
  wire [9:0] ov = v - offset[4:1];






  assign blue = visible & ~green & ~red & (


    (^(oh[4:2] ^ ov[4:2])) & ((oh[4] ^ ov[4]) ? (oh[0] & ov[0]) : (oh[0] ^ ov[0]))




  );



endmodule
