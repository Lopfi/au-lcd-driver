`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////

module video_lvds(
    input clk72_g,
    input HSync,
    input VSync,
    input DataEnable,
    input [5:0] Red,
    input [5:0] Green,
    input [5:0] Blue,
    input rst,
    //lvds outputs
    output pixel_clk,
    output clock_p, clock_n,
    output [2:0] dataout1_p, dataout1_n  // lvds channel 1 data outputs
    );
localparam   SIM_DEVICE   = "ULTRASCALE" ; // Set for the family <ULTRASCALE | ULTRASCALE_PLUS>

wire clkdiv2;
wire clkdiv4;
wire locked;

reg [3:0] px_locked;
wire px_reset;
wire reset_int;
	 
wire [20:0] VideoData;

// Clock Generation
tx_clkgen_7to1 tx_clkgen (
        .clkin     (clk72_g),
        .rst       (rst), 

        .px_clk      (pixel_clk),   // Transmit pixel clock for internal logic
        .tx_clkdiv2  (clkdiv2),  // Transmit clock at 1/2 data rate
        .tx_clkdiv4  (clkdiv4),  // Transmit clock at 1/4 data rate
        .cmt_locked  (locked)
     );


//
// Synchronize locked status to TX px_clk domain
//
always @ (posedge pixel_clk or negedge locked) //cr993494
begin
    if (!locked)
       px_locked <= 4'b000;
    else
       px_locked <= {1'b1,px_locked[3:1]};
end
assign px_reset = !px_locked[0];

assign VideoData[20:14]	= {Blue[2],Blue[3],Blue[4],Blue[5],HSync,VSync,DataEnable};
assign VideoData[13:7]  = {Green[1],Green[2],Green[3],Green[4],Green[5],Blue[0],Blue[1]};
assign VideoData[6:0]	= {Red[0],Red[1],Red[2],Red[3],Red[4],Red[5],Green[0]};

tx_channel_7to1 #(
      .LINES          (3),           // 5 Data Lines
      .DATA_FORMAT    ("PER_LINE"),  // PER_CLOCK or PER_LINE data formatting
      .CLK_PATTERN    (7'b1100011),  // Clock bit pattern
      .TX_SWAP_MASK   (3'h0),        // Output inversion for P/N swap 0=Non Inverted, 1=Inverted
      .SIM_DEVICE    (SIM_DEVICE)
   )
   tx_channel1 (
      .px_data        (VideoData),
      .px_reset       (px_reset),
      .px_clk         (pixel_clk),
      .tx_clkdiv2     (clkdiv2),
      .tx_clkdiv4     (clkdiv4),
      .tx_clk_p       (clock_p),
      .tx_clk_n       (clock_n),
      .tx_out_p       (dataout1_p),
      .tx_out_n       (dataout1_n)
   );


endmodule
