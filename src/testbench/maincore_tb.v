`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////

module maincore_tb;

reg clk = 0, rst_n;

always begin
    #5 clk = ~clk;
end

wire clock_p, clock_n;
wire [2:0] dataout_p, dataout_n;
wire [7:0] led;
wire usb_rx, usb_tx, led_en, led_pwm;

maincore uut(
    .clk(clk),
    .rst_n(rst_n),
	.dataout_p(dataout_p), 
	.dataout_n(dataout_n),
	.clkout_p(clock_p),
	.clkout_n(clock_n),
	.led(led), //status LEDss
    .usb_rx(usb_rx), //USB RX
    .usb_tx(usb_tx), //USB TX
	.led_en(led_en), 
	.led_pwm(led_pwm) //LED enable and PWM control for screen backlight

);

 initial begin 
    #100
    rst_n = 1;
    #100
    rst_n = 0;
    #100
    rst_n = 1;
    
    #20000000
    $finish;
end

endmodule
