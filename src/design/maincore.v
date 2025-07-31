`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////

module maincore(
    input clk,	//100MHz clk in
    input rst_n, //active low reset
    output[7:0] led, //status LEDss
    input usb_rx, //USB RX
    output usb_tx, //USB TX
	output led_en, led_pwm, //LED enable and PWM control for screen backlight
	//lvds outputs
	output clkout_p, clkout_n,
	output [2:0] dataout_p, dataout_n  // lvds channel 1 data outputs
	);

parameter ScreenX = 1366; //1366
parameter ScreenY = 768;  //768
parameter BlankingVertical = 12;
parameter BlankingHorizontal = 174;

parameter FrontPorchHorizontal = 30;
parameter BackPorchHorizontal = 30;
parameter SyncPulseHorizontal = 114;

parameter FrontPorchVertical = 3;
parameter BackPorchVertical = 4;
parameter SyncPulseVertical = 5;

parameter SyncOn = 1;
parameter SyncOff = ~SyncOn; 

parameter integer     D = 3 ;				// Set the number of outputs per channel to be 3
parameter integer     N = 1 ;				// Set the number of channels to be 1

wire clk100_g;
wire clk72_g;
wire pixel_clk;

wire rst;

assign rst = ~rst_n;
	
assign led = rst ? 8'hAA : 8'h55; // debugging pattern
assign usb_tx = usb_rx;

reg [5:0] Red = 0;
reg [5:0] Blue = 0;
reg [5:0] Green = 0;

wire [20:0] VideoData;
wire		txclk ;			
wire		txclk_div ;			
wire		not_tx_mmcm_lckd ;	
wire		tx_mmcm_lckd ;

reg HSync = SyncOff;
reg VSync = SyncOff;
reg DataEnable = 0;


reg [10:0] PosX = 0;
reg [10:0] PosY = 0;

assign led_en = 1;
assign led_pwm = 1;

// Input Clock Buffer
BUFG bg_ref (
    .I		(clk),
    .O      (clk100_g)
	);

// Pixel Clock Generator
clk_wiz_pixel clk_pixel(
    .clk_in(clk100_g),
    .clk_out(clk72_g),
    .reset(rst)
	);

assign VideoData[20:18] = {HSync, VSync, DataEnable}; // Move to higher bits
assign VideoData[17:0]  = {Green[5:0], Red[5:0], Blue[5:0]};

// Clock Input

clock_generator_pll_7_to_1_diff_ddr #(
	.PIXEL_CLOCK		("BUF_G"),
	.INTER_CLOCK 		("BUF_G"),
	.TX_CLOCK			("BUF_G"),
	.USE_PLL			("FALSE"),
	.MMCM_MODE			(2),				// Parameter to set multiplier for MMCM to get VCO in correct operating range. 1 multiplies input clock by 7, 2 multiplies clock by 14, etc
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
	.DATA_FORMAT 	("PER_CLOCK")) 			// PER_CLOCK or PER_CHANL data formatting
dataout (                      
	.dataout_p  	(dataout_p),
	.dataout_n  	(dataout_n),
	.clkout_p  		(clkout_p),
	.clkout_n  		(clkout_n),
	.txclk    		(txclk),
	.txclk_div    	(txclk_div),
	.pixel_clk		(pixel_clk),
	.reset   		(not_tx_mmcm_lckd),
	.clk_pattern  	(7'b1100011),			// Transmit a constant to make the clock
	.datain  		(VideoData)
	);



//Cycle Generator
always @(posedge pixel_clk)
begin
			// Increment horizontal position
			PosX <= PosX + 1;
			
			// Start horizontal blanking
			if (PosX == ScreenX) begin
				DataEnable <= 0;
			end
			
			// Start horizontal sync
			if (PosX == ScreenX + FrontPorchHorizontal) begin
				HSync <= SyncOn;
			end

			// End horizontal sync
			if (PosX == ScreenX + FrontPorchHorizontal + SyncPulseHorizontal) begin
				HSync <= SyncOff;
			end
					
			// End of line						
			if(PosX == (ScreenX+BlankingHorizontal))
			begin
			        PosX <= 0;
					PosY <= PosY + 1;

        			// Start vertical blanking
					if(PosY == ScreenY)
					begin
							DataEnable	<= 0;
					end
					
					// Start vertical sync
					if(PosY == ScreenY + FrontPorchVertical)
					begin
							VSync <= SyncOn;
					end

					// End vertical sync
					if(PosY == ScreenY + FrontPorchVertical + SyncPulseVertical)
					begin
							VSync <= SyncOff;
					end

					// End of frame
					if(PosY == (ScreenY+BlankingVertical))
					begin
							PosY <= 0;
							VSync <= SyncOff;
					end
           end
		   else if (PosX == 0 && PosY < ScreenY)
		   begin
				DataEnable <= 1;
		   end             
end

//Video Generator
always @(posedge pixel_clk)
begin
    if (DataEnable) begin
		if (PosY < ScreenY / 2) begin
			// Generate stripes based on the horizontal position (PosX)
			if (PosX < ScreenX / 4) begin
				// Red stripe
				Red   <= 63;  // Maximum red
				Green <= 0;   // No green
				Blue  <= 0;   // No blue
			end else if (PosX < ScreenX / 2) begin
				// Green stripe
				Red   <= 0;   // No red
				Green <= 63;  // Maximum green
				Blue  <= 0;   // No blue
			end else if (PosX < 3 * ScreenX / 4) begin
				// Blue stripe
				Red   <= 0;   // No red
				Green <= 0;   // No green
				Blue  <= 63;  // Maximum blue
			end else begin
				// White stripe
				Red   <= 0;  // Maximum red
				Green <= 0;  // Maximum green
				Blue  <= 0;  // Maximum blue
			end
		end else begin
			Red   <= 0;  // No red
			Green <= 0;  // No green
			Blue  <= 0;  // No blue
		end
    end else begin
        // Blank when data enable is off
        Red   <= 0;
        Green <= 0;
        Blue  <= 0;
    end
end

endmodule