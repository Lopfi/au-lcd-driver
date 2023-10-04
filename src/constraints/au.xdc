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

#set_property -dict { PACKAGE_PIN K13   IOSTANDARD LVCMOS33 } [get_ports { LED[0] }];
#set_property -dict { PACKAGE_PIN K12   IOSTANDARD LVCMOS33 } [get_ports { LED[1] }];
#set_property -dict { PACKAGE_PIN L14   IOSTANDARD LVCMOS33 } [get_ports { LED[2] }];
#set_property -dict { PACKAGE_PIN l13   IOSTANDARD LVCMOS33 } [get_ports { LED[3] }];
#set_property -dict { PACKAGE_PIN M16   IOSTANDARD LVCMOS33 } [get_ports { LED[4] }];
#set_property -dict { PACKAGE_PIN M14   IOSTANDARD LVCMOS33 } [get_ports { LED[5] }];
#set_property -dict { PACKAGE_PIN M12   IOSTANDARD LVCMOS33 } [get_ports { LED[6] }];
#set_property -dict { PACKAGE_PIN N16   IOSTANDARD LVCMOS33 } [get_ports { LED[7] }];



## Buttons

set_property -dict { PACKAGE_PIN P6   IOSTANDARD LVCMOS33 } [get_ports rst]; ## IO_25_14
set_input_delay -clock clk -max 0.6 [get_ports rst];

## LVDS Outputs
set_property -dict { PACKAGE_PIN N3   IOSTANDARD LVDS_25 } [get_ports clock_p]; ## C12
set_property -dict { PACKAGE_PIN N2   IOSTANDARD LVDS_25 } [get_ports clock_n]; ## C11
set_property -dict { PACKAGE_PIN M5   IOSTANDARD LVDS_25 } [get_ports dataout1_p[0]]; ## C21
set_property -dict { PACKAGE_PIN N4   IOSTANDARD LVDS_25 } [get_ports dataout1_n[0]]; ## C20
set_property -dict { PACKAGE_PIN L4   IOSTANDARD LVDS_25 } [get_ports dataout1_p[1]]; ## C18
set_property -dict { PACKAGE_PIN M4   IOSTANDARD LVDS_25 } [get_ports dataout1_n[1]]; ## C17
set_property -dict { PACKAGE_PIN P4   IOSTANDARD LVDS_25 } [get_ports dataout1_p[2]]; ## C15
set_property -dict { PACKAGE_PIN P3   IOSTANDARD LVDS_25 } [get_ports dataout1_n[2]]; ## C14
