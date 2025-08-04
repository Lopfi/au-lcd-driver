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

parameter screnn_width = 1366; //1366
parameter screnn_height = 768;  //768

parameter frame_width = 1540; //1540
parameter frame_height = 780; //780

// Total horizontal blank time is 174 pixels
parameter H_FP = 14; // Horizontal Front Porch
parameter H_SYNC = 56; // Horizontal Sync Pulse Size
parameter H_BP = 104; // Horizontal Back Porch

// Total vertical blank time is 12 lines
parameter V_FP = 3; // Vertical Front Porch
parameter V_SYNC = 5; // Vertical Sync Pulse Size
parameter V_BP = 4; // Vertical Back Porch

parameter sync_on = 0;
parameter sync_off = ~sync_on; 

parameter integer     D = 3 ;				// Set the number of outputs per channel to be 3
parameter integer     N = 1 ;				// Set the number of channels to be 1

wire clk100_g;
wire clk72_g;
wire pixel_clk;

wire rst;

assign rst = ~rst_n;
	
assign led = rst ? 8'hAA : 8'h55; // debugging pattern
assign usb_tx = usb_rx;

reg [5:0] red = 0;
reg [5:0] blue = 0;
reg [5:0] green = 0;

wire [20:0] VideoData;
wire txclk ;			
wire txclk_div ;			
wire not_tx_mmcm_lckd ;	
wire tx_mmcm_lckd ;

reg hsync = sync_off;
reg vsync = sync_off;
reg data_en = 0;


reg [10:0] pos_x = 0;
reg [10:0] pos_y = 0;

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

assign VideoData[20:18] = {hsync, vsync, data_en}; // Move to higher bits
assign VideoData[17:0]  = {green[5:0], red[5:0], blue[5:0]};

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


assign data_en = (pos_x < screnn_width && pos_y < screnn_height);

assign hsync = ~((pos_x >= (screnn_width + H_FP)) &&
                 (pos_x <  (screnn_width + H_FP + H_SYNC)));


assign vsync = ~((pos_y >= (V_ACTIVE + V_FP)) &&
                 (pos_y <  (V_ACTIVE + V_FP + V_SYNC)));

//Video Generator
always @(posedge pixel_clk)
begin
    if (data_en) begin
		if (pos_y < screnn_height / 2) begin
			// Generate stripes based on the horizontal position (pos_x)
			if (pos_x < screnn_width / 4) begin
				// red stripe
				red   <= 63;  // Maximum red
				green <= 0;   // No green
				blue  <= 0;   // No blue
			end else if (pos_x < screnn_width / 2) begin
				// green stripe
				red   <= 0;   // No red
				green <= 63;  // Maximum green
				blue  <= 0;   // No blue
			end else if (pos_x < 3 * screnn_width / 4) begin
				// blue stripe
				red   <= 0;   // No red
				green <= 0;   // No green
				blue  <= 63;  // Maximum blue
			end else begin
				// White stripe
				red   <= 0;  // Maximum red
				green <= 0;  // Maximum green
				blue  <= 0;  // Maximum blue
			end
		end else begin
			red   <= 0;  // No red
			green <= 0;  // No green
			blue  <= 0;  // No blue
		end
    end else begin
        // Blank when data enable is off
        red   <= 0;
        green <= 0;
        blue  <= 0;
    end
end

endmodule