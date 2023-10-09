`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////

module maincore(
    input clk,	//100MHz clk in
    input rst,	//reset button
	//lvds outputs
	output clkout_p, clkout_n,
	output [2:0] dataout_p, dataout_n  // lvds channel 1 data outputs
	);

/*
parameter ScreenX = 1366;
parameter ScreenY = 768;
parameter BlankingVertical = 12;
parameter BlankingHorizontal = 169;
*/

parameter ScreenX = 1366;
parameter ScreenY = 768;
parameter BlankingVertical = 12;
parameter BlankingHorizontal = 169;

parameter integer     D = 3 ;				// Set the number of outputs per channel to be 3
parameter integer     N = 1 ;				// Set the number of channels to be 1

wire clk100_g;
wire clk72_g;
wire pixel_clk;


reg [5:0] Red = 0;
reg [5:0] Blue = 0;
reg [5:0] Green = 0;

wire [20:0] VideoData;
wire		txclk ;			
wire		txclk_div ;			
wire		not_tx_mmcm_lckd ;	
wire		tx_mmcm_lckd ;

reg HSync = 1, VSync = 1, DataEnable = 0;


reg [10:0] PosX = 0;
reg [10:0] PosY = 0;

reg [7:0] SendFrames = 0;

// Input Clock Buffer
BUFG bg_ref (
    .I             (clk),
    .O             (clk100_g)
	);

// Pixel Clock Generator
clk_wiz_72 clk_wiz_pixel(
    .clk_in(clk100_g),
    .clk_out(clk72_g),
    .reset(rst)
	);

assign VideoData[20:14]	= {Blue[2],Blue[3],Blue[4],Blue[5],HSync,VSync,DataEnable};
assign VideoData[13:7]  = {Green[1],Green[2],Green[3],Green[4],Green[5],Blue[0],Blue[1]};
assign VideoData[6:0]	= {Red[0],Red[1],Red[2],Red[3],Red[4],Red[5],Green[0]};



reg [5:0] Parallax = 0;


// Clock Input

clock_generator_pll_7_to_1_diff_ddr #(
	.PIXEL_CLOCK		("BUF_G"),
	.INTER_CLOCK 		("BUF_G"),
	.TX_CLOCK		("BUF_G"),
	.USE_PLL		("FALSE"),
	.MMCM_MODE		(2),				// Parameter to set multiplier for MMCM to get VCO in correct operating range. 1 multiplies input clock by 7, 2 multiplies clock by 14, etc
	.CLKIN_PERIOD 		(13.889))
clkgen (                        
	.reset			(rst),
	.clkin		    (clk72_g),
	.txclk			(txclk),
	.txclk_div		(txclk_div),
	.pixel_clk		(pixel_clk),
	.status			(),
	.mmcm_lckd		(tx_mmcm_lckd)) ;

assign not_tx_mmcm_lckd = ~tx_mmcm_lckd ;

// Transmitter Logic for N D-bit channels
n_x_serdes_7_to_1_diff_ddr #(
      	.D			(D),
      	.N			(N),				// 1 channel
	.DATA_FORMAT 		("PER_CLOCK")) 			// PER_CLOCK or PER_CHANL data formatting
dataout (                      
	.dataout_p  		(dataout_p),
	.dataout_n  		(dataout_n),
	.clkout_p  		(clkout_p),
	.clkout_n  		(clkout_n),
	.txclk    		(txclk),
	.txclk_div    		(txclk_div),
	.pixel_clk		(pixel_clk),
	.reset   		(not_tx_mmcm_lckd),
	.clk_pattern  		(7'b1100011),			// Transmit a constant to make the clock
	.datain  		(VideoData)
	);



//Cycle Generator
always @(posedge pixel_clk)
begin
			//Sync Generator
			PosX <= PosX + 1;
							
			if(PosX == ScreenX)
			begin
					DataEnable	 	<= 0;
					HSync 			<= 0;
			end
			
			if((PosX == 0) & (PosY < ScreenY))
					DataEnable 	<= 1;
				
			if(PosX == (ScreenX+BlankingHorizontal))
					HSync 			<= 1;
						
			if(PosX == (ScreenX+BlankingHorizontal))
			begin
					if(PosY == ScreenY)
					begin
							VSync 		<= 0;
							DataEnable	<= 0;
					end
					
					if(PosY == (ScreenY+BlankingVertical))
					begin
							VSync 		<= 1;
							Parallax 	<= Parallax - 1;
							PosY 	<= 0;
							PosX 	<= 0;
					end
					else
							PosY <= PosY +1;
					end
						
			if(PosX == (ScreenX+BlankingHorizontal))
					PosX 	<= 0;
end
//Video Generator
always @(posedge pixel_clk)
begin
		if(PosX == ScreenX)
		begin
				Blue 				<= 0;
				Red 				<= 0;
				Green 			<= 0;
		end
		else
		begin
			//Center 640x400 - Screen 640x480 -> Box: 640-320,400-240,640+320,400+240
			
			if( (PosX > 320 && PosY > 160) && ( PosX < 960 && PosY < 640) )
			begin
				// ScreenBox
				Blue <= 0;
				Red <= 0;
				Green <= 0;
			end
			// 3px border: (317,160),(317,640),(319,640),(319,160)
			// 3px border: (317,157),(960,157),(960,160),(317,160)
			else if ( (PosX >= 317 && PosY >= 160 && PosY <= 640 && PosX <= 320) || 
						 (PosX >= 317 && PosY >= 157 && PosY <= 160 && PosX <= 963) || 
						 (PosX >= 960 && PosY >= 157 && PosY <= 640 && PosX <= 963) || 
						 (PosX >= 317 && PosY >= 640 && PosY <= 643 && PosX <= 963)  )
			begin
					Red		<= 255;
					Green		<= 0;
					Blue		<= 0;
			end
			else
			begin
					Red	 	<= ( ( (PosY[5:0]+Parallax) ^ (PosX[5:0]+Parallax) 	) * 2	);
					Blue 		<= ( ( (PosY[5:0]+Parallax) ^ (PosX[5:0]+Parallax) 	) * 3	);
					Green 	<= ( ( (PosY[5:0]+Parallax) ^ (PosX[5:0]+Parallax) 	) * 4	);
			end
		end
end
endmodule
