set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
set_property BITSTREAM.CONFIG.CONFIGRATE 33 [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property CFGBVS VCCO [current_design]
set_property BITSTREAM.CONFIG.SPI_32BIT_ADDR NO [current_design]
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 1 [current_design]
set_property BITSTREAM.CONFIG.SPI_FALL_EDGE YES [current_design]

## Clock signal
set_property -dict { PACKAGE_PIN N14    IOSTANDARD LVCMOS33 } [get_ports clk];
create_clock -period 10.00 -waveform {0 5} [get_ports clk];


## LEDs

set_property -dict { PACKAGE_PIN K13   IOSTANDARD LVCMOS33 } [get_ports { led[0] }];
set_property -dict { PACKAGE_PIN K12   IOSTANDARD LVCMOS33 } [get_ports { led[1] }];
set_property -dict { PACKAGE_PIN L14   IOSTANDARD LVCMOS33 } [get_ports { led[2] }];
set_property -dict { PACKAGE_PIN l13   IOSTANDARD LVCMOS33 } [get_ports { led[3] }];
set_property -dict { PACKAGE_PIN M16   IOSTANDARD LVCMOS33 } [get_ports { led[4] }];
set_property -dict { PACKAGE_PIN M14   IOSTANDARD LVCMOS33 } [get_ports { led[5] }];
set_property -dict { PACKAGE_PIN M12   IOSTANDARD LVCMOS33 } [get_ports { led[6] }];
set_property -dict { PACKAGE_PIN N16   IOSTANDARD LVCMOS33 } [get_ports { led[7] }];

set_property -dict { PACKAGE_PIN P15   IOSTANDARD LVCMOS33 } [get_ports { usb_tx }]; # Shared with USB_TXD ##BD14
set_property -dict { PACKAGE_PIN P16   IOSTANDARD LVCMOS33 } [get_ports { usb_rx }]; # Shared with USB_RXD ##BD15


## Buttons

set_property -dict { PACKAGE_PIN P6   IOSTANDARD LVCMOS33 } [get_ports rst_n]; ## IO_25_14
set_input_delay -clock clk -max 0.6 [get_ports rst_n];

set_property -dict { PACKAGE_PIN T13   IOSTANDARD LVCMOS33 } [get_ports { led_en }];
set_property -dict { PACKAGE_PIN R13   IOSTANDARD LVCMOS33 } [get_ports { led_pwm }];

## LVDS Outputs ##LVDS_25
#set_property -dict { PACKAGE_PIN N3   IOSTANDARD LVDS_25 } [get_ports clkout_p]; ## C12
#set_property -dict { PACKAGE_PIN N2   IOSTANDARD LVDS_25 } [get_ports clkout_n]; ## C11
#set_property -dict { PACKAGE_PIN M5   IOSTANDARD LVDS_25 } [get_ports dataout_p[0]]; ## C21
#set_property -dict { PACKAGE_PIN N4   IOSTANDARD LVDS_25 } [get_ports dataout_n[0]]; ## C20
#set_property -dict { PACKAGE_PIN L4   IOSTANDARD LVDS_25 } [get_ports dataout_p[1]]; ## C18
#set_property -dict { PACKAGE_PIN M4   IOSTANDARD LVDS_25 } [get_ports dataout_n[1]]; ## C17
#set_property -dict { PACKAGE_PIN P4   IOSTANDARD LVDS_25 } [get_ports dataout_p[2]]; ## C15
#set_property -dict { PACKAGE_PIN P3   IOSTANDARD LVDS_25 } [get_ports dataout_n[2]]; ## C14

# Original
set_property -dict { PACKAGE_PIN G2   IOSTANDARD TMDS_33 } [get_ports clkout_p]; ## A21
set_property -dict { PACKAGE_PIN G1   IOSTANDARD TMDS_33 } [get_ports clkout_n]; ## A20
set_property -dict { PACKAGE_PIN H2   IOSTANDARD TMDS_33 } [get_ports dataout_p[2]]; ## A18
set_property -dict { PACKAGE_PIN H1   IOSTANDARD TMDS_33 } [get_ports dataout_n[2]]; ## A17
set_property -dict { PACKAGE_PIN K1   IOSTANDARD TMDS_33 } [get_ports dataout_p[1]]; ## A15
set_property -dict { PACKAGE_PIN J1   IOSTANDARD TMDS_33 } [get_ports dataout_n[1]]; ## A14
set_property -dict { PACKAGE_PIN L3   IOSTANDARD TMDS_33 } [get_ports dataout_p[0]]; ## A12
set_property -dict { PACKAGE_PIN L2   IOSTANDARD TMDS_33 } [get_ports dataout_n[0]]; ## A11
