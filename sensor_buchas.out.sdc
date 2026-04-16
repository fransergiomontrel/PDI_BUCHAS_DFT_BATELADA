## Generated SDC file "sensor_buchas.out.sdc"

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

## DATE    "Sun Apr 25 09:04:47 2021"

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
create_clock -name {host_SCLK} -period 100.000 -waveform { 0.000 50.000 } [get_ports { host_SCLK }]
create_clock -name {rw_data_module:inst14|dffes:SCLK_ff|ff} -period 100.000 -waveform { 0.000 50.000 } [get_keepers {rw_data_module:inst14|dffes:SCLK_ff|ff}]


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



#**************************************************************
# Set Output Delay
#**************************************************************



#**************************************************************
# Set Clock Groups
#**************************************************************



#**************************************************************
# Set False Path
#**************************************************************

set_false_path  -from  [get_clocks {host_SCLK}]  -to  [get_clocks {clk}]
set_false_path  -from  [get_clocks {clk}]  -to  [get_clocks {host_SCLK}]


#**************************************************************
# Set Multicycle Path
#**************************************************************

set_multicycle_path -setup -end -from [get_cells {inst13|storer|channel_counter|ffs[0] inst13|storer|channel_counter|ffs[1] inst13|storer|channel_counter|ffs[2] inst13|storer|channel_counter|ffs[2]~3 inst13|storer|channel_counter|ffs[3] inst13|storer|channel_counter|ffs[3]~1}] -to [get_cells {inst13|crc|lfsr_q[0] inst13|crc|lfsr_q[1] inst13|crc|lfsr_q[2] inst13|crc|lfsr_q[3] inst13|crc|lfsr_q[4] inst13|crc|lfsr_q[5] inst13|crc|lfsr_q[6] inst13|crc|lfsr_q[7] inst13|crc|lfsr_q[8] inst13|crc|lfsr_q[9] inst13|crc|lfsr_q[10] inst13|crc|lfsr_q[11] inst13|crc|lfsr_q[12] inst13|crc|lfsr_q[13] inst13|crc|lfsr_q[14] inst13|crc|lfsr_q[15]}] 2
set_multicycle_path -setup -end -from [get_cells {inst13|serializer|data_buffer[0][0]|ff inst13|serializer|data_buffer[0][1]|ff inst13|serializer|data_buffer[0][2]|ff inst13|serializer|data_buffer[0][3]|ff inst13|serializer|data_buffer[0][4]|ff inst13|serializer|data_buffer[0][5]|ff inst13|serializer|data_buffer[0][6]|ff inst13|serializer|data_buffer[0][7]|ff inst13|serializer|data_buffer[0][8]|ff inst13|serializer|data_buffer[0][9]|ff inst13|serializer|data_buffer[0][10]|ff inst13|serializer|data_buffer[0][11]|ff inst13|serializer|data_buffer[0][12]|ff inst13|serializer|data_buffer[0][13]|ff inst13|serializer|data_buffer[0][14]|ff inst13|serializer|data_buffer[0][15]|ff inst13|serializer|data_buffer[1][0]|ff inst13|serializer|data_buffer[1][1]|ff inst13|serializer|data_buffer[1][2]|ff inst13|serializer|data_buffer[1][3]|ff inst13|serializer|data_buffer[1][4]|ff inst13|serializer|data_buffer[1][5]|ff inst13|serializer|data_buffer[1][6]|ff inst13|serializer|data_buffer[1][7]|ff inst13|serializer|data_buffer[1][8]|ff inst13|serializer|data_buffer[1][9]|ff inst13|serializer|data_buffer[1][10]|ff inst13|serializer|data_buffer[1][11]|ff inst13|serializer|data_buffer[1][12]|ff inst13|serializer|data_buffer[1][13]|ff inst13|serializer|data_buffer[1][14]|ff inst13|serializer|data_buffer[1][15]|ff inst13|serializer|data_buffer[2][0]|ff inst13|serializer|data_buffer[2][1]|ff inst13|serializer|data_buffer[2][2]|ff inst13|serializer|data_buffer[2][3]|ff inst13|serializer|data_buffer[2][4]|ff inst13|serializer|data_buffer[2][5]|ff inst13|serializer|data_buffer[2][6]|ff inst13|serializer|data_buffer[2][7]|ff inst13|serializer|data_buffer[2][8]|ff inst13|serializer|data_buffer[2][9]|ff inst13|serializer|data_buffer[2][10]|ff inst13|serializer|data_buffer[2][11]|ff inst13|serializer|data_buffer[2][12]|ff inst13|serializer|data_buffer[2][13]|ff inst13|serializer|data_buffer[2][14]|ff inst13|serializer|data_buffer[2][15]|ff inst13|serializer|data_buffer[3][0]|ff inst13|serializer|data_buffer[3][1]|ff inst13|serializer|data_buffer[3][2]|ff inst13|serializer|data_buffer[3][3]|ff inst13|serializer|data_buffer[3][4]|ff inst13|serializer|data_buffer[3][5]|ff inst13|serializer|data_buffer[3][6]|ff inst13|serializer|data_buffer[3][7]|ff inst13|serializer|data_buffer[3][8]|ff inst13|serializer|data_buffer[3][9]|ff inst13|serializer|data_buffer[3][10]|ff inst13|serializer|data_buffer[3][11]|ff inst13|serializer|data_buffer[3][12]|ff inst13|serializer|data_buffer[3][13]|ff inst13|serializer|data_buffer[3][14]|ff inst13|serializer|data_buffer[3][15]|ff inst13|serializer|data_buffer[4][0]|ff inst13|serializer|data_buffer[4][1]|ff inst13|serializer|data_buffer[4][2]|ff inst13|serializer|data_buffer[4][3]|ff inst13|serializer|data_buffer[4][4]|ff inst13|serializer|data_buffer[4][5]|ff inst13|serializer|data_buffer[4][6]|ff inst13|serializer|data_buffer[4][7]|ff inst13|serializer|data_buffer[4][8]|ff inst13|serializer|data_buffer[4][9]|ff inst13|serializer|data_buffer[4][10]|ff inst13|serializer|data_buffer[4][11]|ff inst13|serializer|data_buffer[4][12]|ff inst13|serializer|data_buffer[4][13]|ff inst13|serializer|data_buffer[4][14]|ff inst13|serializer|data_buffer[4][15]|ff inst13|serializer|data_buffer[5][0]|ff inst13|serializer|data_buffer[5][1]|ff inst13|serializer|data_buffer[5][2]|ff inst13|serializer|data_buffer[5][3]|ff inst13|serializer|data_buffer[5][4]|ff inst13|serializer|data_buffer[5][5]|ff inst13|serializer|data_buffer[5][6]|ff inst13|serializer|data_buffer[5][7]|ff inst13|serializer|data_buffer[5][8]|ff inst13|serializer|data_buffer[5][9]|ff inst13|serializer|data_buffer[5][10]|ff inst13|serializer|data_buffer[5][11]|ff inst13|serializer|data_buffer[5][12]|ff inst13|serializer|data_buffer[5][13]|ff inst13|serializer|data_buffer[5][14]|ff inst13|serializer|data_buffer[5][15]|ff}] -to [get_cells {inst13|crc|lfsr_q[0] inst13|crc|lfsr_q[1] inst13|crc|lfsr_q[2] inst13|crc|lfsr_q[3] inst13|crc|lfsr_q[4] inst13|crc|lfsr_q[5] inst13|crc|lfsr_q[6] inst13|crc|lfsr_q[7] inst13|crc|lfsr_q[8] inst13|crc|lfsr_q[9] inst13|crc|lfsr_q[10] inst13|crc|lfsr_q[11] inst13|crc|lfsr_q[12] inst13|crc|lfsr_q[13] inst13|crc|lfsr_q[14] inst13|crc|lfsr_q[15]}] 2
set_multicycle_path -hold -end -from [get_cells {inst13|serializer|data_buffer[0][0]|ff inst13|serializer|data_buffer[0][1]|ff inst13|serializer|data_buffer[0][2]|ff inst13|serializer|data_buffer[0][3]|ff inst13|serializer|data_buffer[0][4]|ff inst13|serializer|data_buffer[0][5]|ff inst13|serializer|data_buffer[0][6]|ff inst13|serializer|data_buffer[0][7]|ff inst13|serializer|data_buffer[0][8]|ff inst13|serializer|data_buffer[0][9]|ff inst13|serializer|data_buffer[0][10]|ff inst13|serializer|data_buffer[0][11]|ff inst13|serializer|data_buffer[0][12]|ff inst13|serializer|data_buffer[0][13]|ff inst13|serializer|data_buffer[0][14]|ff inst13|serializer|data_buffer[0][15]|ff inst13|serializer|data_buffer[1][0]|ff inst13|serializer|data_buffer[1][1]|ff inst13|serializer|data_buffer[1][2]|ff inst13|serializer|data_buffer[1][3]|ff inst13|serializer|data_buffer[1][4]|ff inst13|serializer|data_buffer[1][5]|ff inst13|serializer|data_buffer[1][6]|ff inst13|serializer|data_buffer[1][7]|ff inst13|serializer|data_buffer[1][8]|ff inst13|serializer|data_buffer[1][9]|ff inst13|serializer|data_buffer[1][10]|ff inst13|serializer|data_buffer[1][11]|ff inst13|serializer|data_buffer[1][12]|ff inst13|serializer|data_buffer[1][13]|ff inst13|serializer|data_buffer[1][14]|ff inst13|serializer|data_buffer[1][15]|ff inst13|serializer|data_buffer[2][0]|ff inst13|serializer|data_buffer[2][1]|ff inst13|serializer|data_buffer[2][2]|ff inst13|serializer|data_buffer[2][3]|ff inst13|serializer|data_buffer[2][4]|ff inst13|serializer|data_buffer[2][5]|ff inst13|serializer|data_buffer[2][6]|ff inst13|serializer|data_buffer[2][7]|ff inst13|serializer|data_buffer[2][8]|ff inst13|serializer|data_buffer[2][9]|ff inst13|serializer|data_buffer[2][10]|ff inst13|serializer|data_buffer[2][11]|ff inst13|serializer|data_buffer[2][12]|ff inst13|serializer|data_buffer[2][13]|ff inst13|serializer|data_buffer[2][14]|ff inst13|serializer|data_buffer[2][15]|ff inst13|serializer|data_buffer[3][0]|ff inst13|serializer|data_buffer[3][1]|ff inst13|serializer|data_buffer[3][2]|ff inst13|serializer|data_buffer[3][3]|ff inst13|serializer|data_buffer[3][4]|ff inst13|serializer|data_buffer[3][5]|ff inst13|serializer|data_buffer[3][6]|ff inst13|serializer|data_buffer[3][7]|ff inst13|serializer|data_buffer[3][8]|ff inst13|serializer|data_buffer[3][9]|ff inst13|serializer|data_buffer[3][10]|ff inst13|serializer|data_buffer[3][11]|ff inst13|serializer|data_buffer[3][12]|ff inst13|serializer|data_buffer[3][13]|ff inst13|serializer|data_buffer[3][14]|ff inst13|serializer|data_buffer[3][15]|ff inst13|serializer|data_buffer[4][0]|ff inst13|serializer|data_buffer[4][1]|ff inst13|serializer|data_buffer[4][2]|ff inst13|serializer|data_buffer[4][3]|ff inst13|serializer|data_buffer[4][4]|ff inst13|serializer|data_buffer[4][5]|ff inst13|serializer|data_buffer[4][6]|ff inst13|serializer|data_buffer[4][7]|ff inst13|serializer|data_buffer[4][8]|ff inst13|serializer|data_buffer[4][9]|ff inst13|serializer|data_buffer[4][10]|ff inst13|serializer|data_buffer[4][11]|ff inst13|serializer|data_buffer[4][12]|ff inst13|serializer|data_buffer[4][13]|ff inst13|serializer|data_buffer[4][14]|ff inst13|serializer|data_buffer[4][15]|ff inst13|serializer|data_buffer[5][0]|ff inst13|serializer|data_buffer[5][1]|ff inst13|serializer|data_buffer[5][2]|ff inst13|serializer|data_buffer[5][3]|ff inst13|serializer|data_buffer[5][4]|ff inst13|serializer|data_buffer[5][5]|ff inst13|serializer|data_buffer[5][6]|ff inst13|serializer|data_buffer[5][7]|ff inst13|serializer|data_buffer[5][8]|ff inst13|serializer|data_buffer[5][9]|ff inst13|serializer|data_buffer[5][10]|ff inst13|serializer|data_buffer[5][11]|ff inst13|serializer|data_buffer[5][12]|ff inst13|serializer|data_buffer[5][13]|ff inst13|serializer|data_buffer[5][14]|ff inst13|serializer|data_buffer[5][15]|ff}] -to [get_cells {inst13|crc|lfsr_q[0] inst13|crc|lfsr_q[1] inst13|crc|lfsr_q[2] inst13|crc|lfsr_q[3] inst13|crc|lfsr_q[4] inst13|crc|lfsr_q[5] inst13|crc|lfsr_q[6] inst13|crc|lfsr_q[7] inst13|crc|lfsr_q[8] inst13|crc|lfsr_q[9] inst13|crc|lfsr_q[10] inst13|crc|lfsr_q[11] inst13|crc|lfsr_q[12] inst13|crc|lfsr_q[13] inst13|crc|lfsr_q[14] inst13|crc|lfsr_q[15]}] 1
set_multicycle_path -hold -end -from [get_cells {inst13|storer|channel_counter|ffs[0] inst13|storer|channel_counter|ffs[1] inst13|storer|channel_counter|ffs[2] inst13|storer|channel_counter|ffs[2]~3 inst13|storer|channel_counter|ffs[3] inst13|storer|channel_counter|ffs[3]~1}] -to [get_cells {inst13|crc|lfsr_q[0] inst13|crc|lfsr_q[1] inst13|crc|lfsr_q[2] inst13|crc|lfsr_q[3] inst13|crc|lfsr_q[4] inst13|crc|lfsr_q[5] inst13|crc|lfsr_q[6] inst13|crc|lfsr_q[7] inst13|crc|lfsr_q[8] inst13|crc|lfsr_q[9] inst13|crc|lfsr_q[10] inst13|crc|lfsr_q[11] inst13|crc|lfsr_q[12] inst13|crc|lfsr_q[13] inst13|crc|lfsr_q[14] inst13|crc|lfsr_q[15]}] 1


#**************************************************************
# Set Maximum Delay
#**************************************************************



#**************************************************************
# Set Minimum Delay
#**************************************************************



#**************************************************************
# Set Input Transition
#**************************************************************

