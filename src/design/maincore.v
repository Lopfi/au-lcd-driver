`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////

module maincore(
    input clk,	//100MHz clk in
    input rst,	//reset button
	//lvds outputs
	output clock_p, clock_n,
	output [2:0] dataout1_p, dataout1_n  // lvds channel 1 data outputs
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

wire clk100_g;
wire clk72_g;
wire pixel_clk;


reg [5:0] Red = 0;
reg [5:0] Blue = 0;
reg [5:0] Green = 0;

reg HSync = 1, VSync = 1, DataEnable = 0;


reg [10:0] ContadorX = 0; // Contador de colunas
reg [10:0] ContadorY = 0; // Contador de linhas

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
    .resetn(rst)
	);

video_lvds videoencoder (
	.clk72_g(clk72_g),
    .HSync(HSync), 
    .VSync(VSync), 
    .DataEnable(DataEnable), 
    .Red(Red), 
    .Green(Green), 
    .Blue(Blue), 
    .rst(rst),
	
	.pixel_clk(pixel_clk), 
	.clock_p(clock_p), 
    .clock_n(clock_n),
	.dataout1_p(dataout1_p),
	.dataout1_n(dataout1_n)
    );

reg [5:0] Parallax = 0;

//Cycle Generator
always @(posedge pixel_clk)
begin
			//Sync Generator
			ContadorX <= ContadorX + 1;
							
			if(ContadorX == ScreenX)
			begin
					DataEnable	 	<= 0;
					HSync 			<= 0;
			end
			
			if((ContadorX == 0) & (ContadorY < ScreenY))
					DataEnable 	<= 1;
				
			if(ContadorX == (ScreenX+BlankingHorizontal))
					HSync 			<= 1;
						
			if(ContadorX == (ScreenX+BlankingHorizontal))
			begin
					if(ContadorY == ScreenY)
					begin
							VSync 		<= 0;
							DataEnable	<= 0;
					end
					
					if(ContadorY == (ScreenY+BlankingVertical))
					begin
							VSync 		<= 1;
							Parallax 	<= Parallax - 1;
							ContadorY 	<= 0;
							ContadorX 	<= 0;
					end
					else
							ContadorY <= ContadorY +1;
					end
						
			if(ContadorX == (ScreenX+BlankingHorizontal))
					ContadorX 	<= 0;
end
//Video Generator
always @(posedge pixel_clk)
begin
		if(ContadorX == ScreenX)
		begin
				Blue 				<= 0;
				Red 				<= 0;
				Green 			<= 0;
		end
		else
		begin
			//Center 640x400 - Screen 640x480 -> Box: 640-320,400-240,640+320,400+240
			
			if( (ContadorX > 320 && ContadorY > 160) && ( ContadorX < 960 && ContadorY < 640) )
			begin
				// ScreenBox
				Blue <= 0;
				Red <= 0;
				Green <= 0;
			end
			// 3px border: (317,160),(317,640),(319,640),(319,160)
			// 3px border: (317,157),(960,157),(960,160),(317,160)
			else if ( (ContadorX >= 317 && ContadorY >= 160 && ContadorY <= 640 && ContadorX <= 320) || 
						 (ContadorX >= 317 && ContadorY >= 157 && ContadorY <= 160 && ContadorX <= 963) || 
						 (ContadorX >= 960 && ContadorY >= 157 && ContadorY <= 640 && ContadorX <= 963) || 
						 (ContadorX >= 317 && ContadorY >= 640 && ContadorY <= 643 && ContadorX <= 963)  )
			begin
					Red		<= 255;
					Green		<= 0;
					Blue		<= 0;
			end
			else
			begin
					Red	 	<= ( ( (ContadorY[5:0]+Parallax) ^ (ContadorX[5:0]+Parallax) 	) * 2	);
					Blue 		<= ( ( (ContadorY[5:0]+Parallax) ^ (ContadorX[5:0]+Parallax) 	) * 3	);
					Green 	<= ( ( (ContadorY[5:0]+Parallax) ^ (ContadorX[5:0]+Parallax) 	) * 4	);
			end
		end
end
endmodule
