`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////

module maincore_tb;

reg clk = 0, rst;

always begin
    #5 clk = ~clk;
end

wire c1_p, c1_n, c2_p, c2_n, c3_p, c3_n, clock_p, clock_n;

maincore uut(
    .CLK100MHZ(clk),
	.channel1_p(c1_p),
	.channel1_n(c1_n),
	.channel2_p(c2_p),
	.channel2_n(c2_n),
	.channel3_p(c3_p),
	.channel3_n(c3_n),
	.clock_p(clock_p),
	.clock_n(clock_n)
);

 initial begin 
    rst = 0;
    #10
    rst = 1;
    #10
    rst = 0;
    
    #2000
    $finish;
end

endmodule
