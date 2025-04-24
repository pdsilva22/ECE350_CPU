# Set I/O standards for all ports
set_property IOSTANDARD LVCMOS33 [get_ports *]

# 16-bit audio output
set_property PACKAGE_PIN A1  [get_ports {audio_out[0]}]
set_property PACKAGE_PIN B1  [get_ports {audio_out[1]}]
set_property PACKAGE_PIN C1  [get_ports {audio_out[2]}]
set_property PACKAGE_PIN D1  [get_ports {audio_out[3]}]
set_property PACKAGE_PIN E1  [get_ports {audio_out[4]}]
set_property PACKAGE_PIN F1  [get_ports {audio_out[5]}]
set_property PACKAGE_PIN G1  [get_ports {audio_out[6]}]
set_property PACKAGE_PIN H1  [get_ports {audio_out[7]}]
set_property PACKAGE_PIN J1  [get_ports {audio_out[8]}]
set_property PACKAGE_PIN K1  [get_ports {audio_out[9]}]
set_property PACKAGE_PIN L1  [get_ports {audio_out[10]}]
set_property PACKAGE_PIN M1  [get_ports {audio_out[11]}]
set_property PACKAGE_PIN N1  [get_ports {audio_out[12]}]
set_property PACKAGE_PIN P1  [get_ports {audio_out[13]}]
set_property PACKAGE_PIN R1  [get_ports {audio_out[14]}]
set_property PACKAGE_PIN T1  [get_ports {audio_out[15]}]

# 16-bit frequency input
set_property PACKAGE_PIN A2  [get_ports {frequency_in[0]}]
set_property PACKAGE_PIN B2  [get_ports {frequency_in[1]}]
set_property PACKAGE_PIN C2  [get_ports {frequency_in[2]}]
set_property PACKAGE_PIN D2  [get_ports {frequency_in[3]}]
set_property PACKAGE_PIN E2  [get_ports {frequency_in[4]}]
set_property PACKAGE_PIN F2  [get_ports {frequency_in[5]}]
set_property PACKAGE_PIN G2  [get_ports {frequency_in[6]}]
set_property PACKAGE_PIN H2  [get_ports {frequency_in[7]}]
set_property PACKAGE_PIN J2  [get_ports {frequency_in[8]}]
set_property PACKAGE_PIN K2  [get_ports {frequency_in[9]}]
set_property PACKAGE_PIN L2  [get_ports {frequency_in[10]}]
set_property PACKAGE_PIN M2  [get_ports {frequency_in[11]}]
set_property PACKAGE_PIN N2  [get_ports {frequency_in[12]}]
set_property PACKAGE_PIN P2  [get_ports {frequency_in[13]}]
set_property PACKAGE_PIN R2  [get_ports {frequency_in[14]}]
set_property PACKAGE_PIN T2  [get_ports {frequency_in[15]}]

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
set_property -dict { PACKAGE_PIN J5   IOSTANDARD LVCMOS33 } [get_ports { micClk }]; 
set_property -dict { PACKAGE_PIN H5   IOSTANDARD LVCMOS33 } [get_ports { micData }]; 

# Switches
set_property -dict { PACKAGE_PIN J15   IOSTANDARD LVCMOS33 } [get_ports { switches[0] }]; 
set_property -dict { PACKAGE_PIN L16   IOSTANDARD LVCMOS33 } [get_ports { switches[1] }];
set_property -dict { PACKAGE_PIN M13   IOSTANDARD LVCMOS33 } [get_ports { switches[2] }];
set_property -dict { PACKAGE_PIN R15   IOSTANDARD LVCMOS33 } [get_ports { switches[3] }]; 
set_property -dict { PACKAGE_PIN R17   IOSTANDARD LVCMOS33 } [get_ports { switches[4] }]; 
set_property -dict { PACKAGE_PIN T18   IOSTANDARD LVCMOS33 } [get_ports { switches[5] }]; 
set_property -dict { PACKAGE_PIN U18   IOSTANDARD LVCMOS33 } [get_ports { switches[6] }]; 
set_property -dict { PACKAGE_PIN R13   IOSTANDARD LVCMOS33 } [get_ports { switches[7] }]; 
set_property -dict { PACKAGE_PIN T8    IOSTANDARD LVCMOS18 } [get_ports { switches[8] }];
set_property -dict { PACKAGE_PIN U8    IOSTANDARD LVCMOS18 } [get_ports { switches[9] }];
set_property -dict { PACKAGE_PIN R16    IOSTANDARD LVCMOS33 } [get_ports { switches[10] }];
set_property -dict { PACKAGE_PIN T13    IOSTANDARD LVCMOS33 } [get_ports { switches[11] }];
set_property -dict { PACKAGE_PIN H6    IOSTANDARD LVCMOS33 } [get_ports { switches[12] }];

# Buttons
# set_property -dict { PACKAGE_PIN M18   IOSTANDARD LVCMOS33 } [get_ports { buttons[0] }]; 
# set_property -dict { PACKAGE_PIN P18   IOSTANDARD LVCMOS33 } [get_ports { buttons[1] }];

# Servo signal
set_property -dict { PACKAGE_PIN D14   IOSTANDARD LVCMOS33 } [get_ports { servoSignal }];  # Pin JB[1]

# Reset Signal
set_property PACKAGE_PIN N17 [get_ports reset]
set_property IOSTANDARD LVCMOS33 [get_ports reset]
