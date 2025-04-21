# Set I/O standards for all ports
set_property IOSTANDARD LVCMOS33 [get_ports *]


# Note on input
set_property PACKAGE_PIN U1  [get_ports note_on]

# Set CFGBVS and CONFIG_VOLTAGE properties
set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]

# PS2 Stuff
set_property PACKAGE_PIN F4 [get_ports ps2_clk]
set_property PACKAGE_PIN B2 [get_ports ps2_data]
set_property IOSTANDARD LVCMOS33 [get_ports ps2_clk]
set_property IOSTANDARD LVCMOS33 [get_ports ps2_data]

# Audio
set_property -dict { PACKAGE_PIN D12   IOSTANDARD LVCMOS33 } [get_ports { audioEn }]; 
set_property -dict { PACKAGE_PIN A11   IOSTANDARD LVCMOS33 } [get_ports { audioOut }]; 
set_property -dict { PACKAGE_PIN F5   IOSTANDARD LVCMOS33 } [get_ports { chSel }]; 
set_property -dict { PACKAGE_PIN E3   IOSTANDARD LVCMOS33 } [get_ports { clk }]; 
#create_clock -add -name sys_clk_pin -period 12.00 -waveform {0 6} [get_ports {clk}]; //83.33 mhz
create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports {clk}]; //100 mhz

set_property -dict { PACKAGE_PIN J5   IOSTANDARD LVCMOS33 } [get_ports { micClk }]; 
set_property -dict { PACKAGE_PIN H5   IOSTANDARD LVCMOS33 } [get_ports { micData }]; 


# Buttons
# set_property -dict { PACKAGE_PIN M18   IOSTANDARD LVCMOS33 } [get_ports { buttons[0] }]; 
# set_property -dict { PACKAGE_PIN P18   IOSTANDARD LVCMOS33 } [get_ports { buttons[1] }];

# Servo signal
set_property -dict { PACKAGE_PIN D14   IOSTANDARD LVCMOS33 } [get_ports { servoSignal }];  # Pin JB[1]

# Reset Signal
set_property PACKAGE_PIN N17 [get_ports reset]
set_property IOSTANDARD LVCMOS33 [get_ports reset]
