`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////

module maincore_tb;

reg clk = 0, rst;

always begin
    #5 clk = ~clk;
end

wire clock_p, clock_n;
wire [2:0] dataout_p, dataout_n;

maincore uut(
    .clk(clk),
    .rst(rst),
	.dataout_p(dataout_p), 
	.dataout_n(dataout_n),
	.clkout_p(clock_p),
	.clkout_n(clock_n)
);

 initial begin 
    #100
    rst = 1;
    #100
    rst = 0;
    #100
    rst = 1;
    
    #200000
    $finish;
end

endmodule
