## Generated SDC file "test_ram.sdc"

## Copyright (C) 2020  Intel Corporation. All rights reserved.
## Your use of Intel Corporation's design tools, logic functions 
## and other software and tools, and any partner logic 
## functions, and any output files from any of the foregoing 
## (including device programming or simulation files), and any 
## associated documentation or information are expressly subject 
## to the terms and conditions of the Intel Program License 
## Subscription Agreement, the Intel Quartus Prime License Agreement,
## the Intel FPGA IP License Agreement, or other applicable license
## agreement, including, without limitation, that your use is for
## the sole purpose of programming logic devices manufactured by
## Intel and sold by Intel or its authorized distributors.  Please
## refer to the applicable agreement for further details, at
## https://fpgasoftware.intel.com/eula.


## VENDOR  "Altera"
## PROGRAM "Quartus Prime"
## VERSION "Version 20.1.1 Build 720 11/11/2020 SJ Lite Edition"

## DATE    "Sat Apr 17 16:12:35 2021"

##
## DEVICE  "EPM1270T144C5"
##


#**************************************************************
# Time Information
#**************************************************************

set_time_format -unit ns -decimal_places 3



#**************************************************************
# Create Clock
#**************************************************************

create_clock -name {clk} -period 10.000 -waveform { 0.000 5.000 } [get_ports { clk }]


#**************************************************************
# Create Generated Clock
#**************************************************************



#**************************************************************
# Set Clock Latency
#**************************************************************



#**************************************************************
# Set Clock Uncertainty
#**************************************************************



#**************************************************************
# Set Input Delay
#**************************************************************
set_input_delay -clock { clk } 2 [get_ports {ram_data_bus[0] ram_data_bus[1] ram_data_bus[2] ram_data_bus[3] ram_data_bus[4] ram_data_bus[5] ram_data_bus[6] ram_data_bus[7] reset}]


#**************************************************************
# Set Output Delay
#**************************************************************
#set_output_delay -clock { clk } 8 [get_ports {cs_n data_out[0] data_out[1] data_out[2] data_out[3] data_out[4] data_out[5] data_out[6] data_out[7] oe_n ram_address[0] ram_address[1] ram_address[2] ram_address[3] ram_address[4] ram_address[5] ram_address[6] ram_address[7] ram_address[8] ram_address[9] ram_address[10] ram_address[11] ram_address[12] ram_address[13] ram_address[14] ram_address[15] ram_address[16] ram_address[17] ram_address[18] ram_cs_n ram_data_bus[0] ram_data_bus[1] ram_data_bus[2] ram_data_bus[3] ram_data_bus[4] ram_data_bus[5] ram_data_bus[6] ram_data_bus[7] ram_oe_n ram_we_n test_mode[0] test_mode[1] test_state[0] test_state[1] test_state[2] test_state[3] test_state[4] test_state[5] test_state[6] test_state[7] test_state[8] test_state[9] test_state[10] test_state[11] test_state[12] test_state[13] we_n}]


#**************************************************************
# Set Clock Groups
#**************************************************************



#**************************************************************
# Set False Path
#**************************************************************



#**************************************************************
# Set Multicycle Path
#**************************************************************



#**************************************************************
# Set Maximum Delay
#**************************************************************



#**************************************************************
# Set Minimum Delay
#**************************************************************



#**************************************************************
# Set Input Transition
#**************************************************************

