//////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2017 Xilinx, Inc.
// This design is confidential and proprietary of Xilinx, All Rights Reserved.
//////////////////////////////////////////////////////////////////////////////
//   ____  ____
//  /   /\/   /
// /___/  \  /   Vendor: Xilinx
// \   \   \/    Version: 1.3
//  \   \        Filename: tx_piso_1to7 .v
//  /   /        Date Last Modified:  06/06/2022
// /___/   /\    Date Created: 02/27/2017
// \   \  /  \
//  \___\/\___\
//
// Device    :  Ultrascale
//
// Purpose   :  Transmit Parallel In Serial Out with 1 to 7 conversion
//
// Parameters:  TX_SWAP_MASK - Binary - Default = 16'b0
//                 - Binary value indicating if an output line is inverted
//
// Reference:	XAPPxxx
//
// Revision History:
//    Rev 1.3 - Add SIM_DEVICE to allow code to work with ULTRASCALE_PLUS  (jimt)
//    Rev 1.0 - Initial Release (knagara)
//    Rev 0.9 - Early Access Release (mcgett)
//////////////////////////////////////////////////////////////////////////////
//
//  Disclaimer:
//
// This disclaimer is not a license and does not grant any rights to the
// materials distributed herewith. Except as otherwise provided in a valid
// license issued to you by Xilinx, and to the maximum extent permitted by
// applicable law:
//
// (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND WITH ALL FAULTS, AND
// XILINX HEREBY DISCLAIMS ALL WARRANTIES AND CONDITIONS, EXPRESS, IMPLIED, OR
// STATUTORY, INCLUDING BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY,
// NON-INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and (2) Xilinx
// shall not be liable (whether in contract or tort, including negligence, or
// under any other theory of liability) for any loss or damage of any kind or
// nature related to, arising under or in connection with these materials,
// including for any direct, or any indirect, special, incidental, or
// consequential loss or damage (including loss of data, profits, goodwill, or
// any type of loss or damage suffered as a result of any action brought by a
// third party) even if such damage or loss was reasonably foreseeable or
// Xilinx had been advised of the possibility of the same.
//
// Critical Applications:
//
// Xilinx products are not designed or intended to be fail-safe, or for use in
// any application requiring fail-safe performance, such as life-support or
// safety devices or systems, class III medical devices, nuclear facilities,
// applications related to the deployment of airbags, or any other applications
// that could lead to death, personal injury, or severe property or
// environmental damage (individually and collectively, "Critical
// Applications"). Customer assumes the sole risk and liability of any use of
// Xilinx products in Critical Applications, subject only to applicable laws
// and regulations governing limitations on product liability.
//
// THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS PART OF THIS FILE
// AT ALL TIMES.
//
//////////////////////////////////////////////////////////////////////////////

`timescale 1ps/1ps

module tx_piso_7to1 # (
      parameter  TX_SWAP_MASK = 1'b0,  // Allows P/N outputs to be inverted pinswap to ease PCB routing 0=normal, 1=swapped
	  parameter         SIM_DEVICE   = "ULTRASCALE"  // Set for the family <ULTRASCALE | ULTRASCALE_PLUS>

   )
   (
      input [6:0] px_data,       // 7-bit pixel data
      input       px_reset,      // Reset for pixel logic synchronus to px_clk
      input       px_clk,        // Pixel clock running at 1/7 transmit rate
      input       tx_enable,     // Transmit enable, synchronous to tx_clkdiv2
      input       tx_clkdiv2,    // Transmit clock running at 1/2 transmit rate
      input       tx_clkdiv4,    // Transmit clock running at 1/4 transmit rate
      output      tx_out_p,      // Transmit output P-side
      output      tx_out_n       // Transmit output N-side
   );

reg  [3:0]  wr_addr;
reg  [3:0]  rd_addr;
wire [6:0]  rd_curr;
reg  [6:1]  rd_last;
reg  [2:0]  rd_state;

reg  [3:0]  tx_data;
wire        oserdes_out;

//
// FIFO Write address is continuous counter
//
always @ (posedge px_clk)
begin
   if (px_reset) begin
       wr_addr <= 4'b0;
   end else begin
       wr_addr <= wr_addr + 1'b1;
   end
end

//
// Generate 7 Dual Port Distributed RAMS for FIFO
//
genvar i;
generate
for (i = 0 ; i <= 6 ; i = i+1) begin : bit
  RAM32X1D mem (
     .D     (px_data[i] ^ TX_SWAP_MASK),
     .WCLK  (px_clk),
     .WE    (!px_reset),
     .A0    (wr_addr[0]),
     .A1    (wr_addr[1]),
     .A2    (wr_addr[2]),
     .A3    (wr_addr[3]),
     .A4    (1'b0),
     .SPO   (),
     .DPRA0 (rd_addr[0]),
     .DPRA1 (rd_addr[1]),
     .DPRA2 (rd_addr[2]),
     .DPRA3 (rd_addr[3]),
     .DPRA4 (1'b0),
     .DPO   (rd_curr[i]));
end

endgenerate

//
// Store last read data for one cycle
//
always @ (posedge tx_clkdiv4)
begin
    rd_last[6:1] <= rd_curr[6:1];
end

//
// Read state machine and gear box
//
always @ (posedge tx_clkdiv4)
begin
   if (!tx_enable) begin
       rd_addr  <= 4'b0;
       rd_state <= 3'h0;
   end else begin
       case (rd_state ) 
         3'h0 : begin 
            rd_addr <= rd_addr + 1'b1;
            tx_data <= rd_curr[3:0];
            rd_state<= rd_state + 1'b1;
            end
         3'h1 : begin 
            rd_addr <= rd_addr; 
            tx_data <= {rd_curr[0], rd_last[6:4]};
            rd_state<= rd_state + 1'b1;
            end
         3'h2 : begin 
            rd_addr <= rd_addr + 1'b1; 
            tx_data <= rd_last[4:1];
            rd_state<= rd_state + 1'b1;
            end
         3'h3 : begin 
            rd_addr <= rd_addr;  
            tx_data <= {rd_curr[1:0], rd_last[6:5]};
            rd_state<= rd_state + 1'b1;
            end
         3'h4 : begin 
            rd_addr <= rd_addr + 1'b1; 
            tx_data <= rd_last[5:2];
            rd_state<= rd_state + 1'b1;
            end
         3'h5 : begin 
            rd_addr <= rd_addr;  
            tx_data <= {rd_curr[2:0], rd_last[6]};
            rd_state<= rd_state + 1'b1;
            end
         3'h6 : begin 
            rd_addr <= rd_addr + 1'b1; 
            tx_data <= rd_last[6:3];
            rd_state<= 3'h0;
            end
       endcase
   end
end

//
// OSERDESE3 in 4:1 DDR Mode
//
OSERDESE2 #(
    .DATA_WIDTH (4)                    // SERDES word width
	)
oserdes_cm (
   .D1(tx_data[0]),
   .D2(tx_data[1]),
   .D3(tx_data[2]),
   .D4(tx_data[3]),
   .T1(1'b0),
   .CLK       (tx_clkdiv2),
   .CLKDIV    (tx_clkdiv4),
   .RST       (!tx_enable),
   .OQ        (oserdes_out),
   .TQ    ());



/*

//
// OSERDESE3 in 4:1 DDR Mode
//
OSERDESE3 #(
    .DATA_WIDTH             (4)                    // SERDES word width
    .INIT                   (0),
    .ODDR_MODE              ("FALSE"),
    .OSERDES_D_BYPASS       ("FALSE"),
    .OSERDES_T_BYPASS       ("FALSE"),
    .SIM_DEVICE             (SIM_DEVICE)
	)
oserdes_cm (
    .D         ({4'b0,tx_data[3:0]}),
    .T         (1'b0),
    .CLK       (tx_clkdiv2),
    .CLKDIV    (tx_clkdiv4),
    .RST       (!tx_enable),
    .OQ        (oserdes_out),
    .T_OUT     ());

    */

//
// LVDS Output Buffer
//
OBUFDS io_clk_out (
    .I         (oserdes_out),
    .O         (tx_out_p),
    .OB        (tx_out_n));

endmodule
  
