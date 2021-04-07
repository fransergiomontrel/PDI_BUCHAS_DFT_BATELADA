// Copyright (C) 2020  Intel Corporation. All rights reserved.
// Your use of Intel Corporation's design tools, logic functions 
// and other software and tools, and any partner logic 
// functions, and any output files from any of the foregoing 
// (including device programming or simulation files), and any 
// associated documentation or information are expressly subject 
// to the terms and conditions of the Intel Program License 
// Subscription Agreement, the Intel Quartus Prime License Agreement,
// the Intel FPGA IP License Agreement, or other applicable license
// agreement, including, without limitation, that your use is for
// the sole purpose of programming logic devices manufactured by
// Intel and sold by Intel or its authorized distributors.  Please
// refer to the applicable agreement for further details, at
// https://fpgasoftware.intel.com/eula.

// PROGRAM		"Quartus Prime"
// VERSION		"Version 20.1.1 Build 720 11/11/2020 SJ Lite Edition"
// CREATED		"Wed Apr 07 15:55:17 2021"

module sensor_buchas_CPLD(
	clk,
	host_rst_n,
	host_convst_start,
	host_MOSI,
	host_SCLK,
	host_SS_n,
	rst,
	adc_rvs,
	adc_sdi,
	host_mode,
	test_addr_clr,
	test_addr_inc,
	ram_we_n,
	ram_cs_n,
	ram_oe_n,
	test_running,
	test_AM_start,
	test_AM_adc_sclk,
	test_AM_adc_convst,
	host_MISO,
	host_busy,
	adc_convst,
	adc_rst_n,
	adc_sclk,
	adc_sdo,
	data_bus,
	ram_address,
	test_sm_state
);


input wire	clk;
input wire	host_rst_n;
input wire	host_convst_start;
input wire	host_MOSI;
input wire	host_SCLK;
input wire	host_SS_n;
input wire	rst;
input wire	[5:0] adc_rvs;
input wire	[5:0] adc_sdi;
input wire	[1:0] host_mode;
output wire	test_addr_clr;
output wire	test_addr_inc;
output wire	ram_we_n;
output wire	ram_cs_n;
output wire	ram_oe_n;
output wire	test_running;
output wire	test_AM_start;
output wire	test_AM_adc_sclk;
output wire	test_AM_adc_convst;
output wire	host_MISO;
output wire	host_busy;
output wire	[5:0] adc_convst;
output wire	[5:0] adc_rst_n;
output wire	[5:0] adc_sclk;
output wire	[5:0] adc_sdo;
inout wire	[7:0] data_bus;
output wire	[18:0] ram_address;
output wire	[2:0] test_sm_state;

wire	AI_changing_mode;
wire	AI_convst;
wire	AI_rst_n;
wire	AI_sclk;
wire	[5:0] AI_sdi;
wire	[5:0] AI_sdo;
wire	AM_adc_convst;
wire	AM_adc_sclk;
wire	[5:0] AM_adc_sdi;
wire	AM_addr_clr;
wire	AM_addr_inc;
wire	AM_busy;
wire	AM_changing_mode;
wire	AM_cs_n;
wire	[7:0] AM_data;
wire	AM_we_n;
wire	HI_busy;
wire	HI_changing_mode;
wire	HI_convst_start;
wire	HI_MISO;
wire	[1:0] HI_mode;
wire	HI_MOSI;
wire	HI_rst_n;
wire	HI_SCLK;
wire	HI_SS_n;
wire	RDM_addr_clr;
wire	RDM_addr_inc;
wire	RDM_busy;
wire	RDM_changing_mode;
wire	RDM_cs_n;
wire	[7:0] RDM_data;
wire	RDM_MISO;
wire	[1:0] RDM_mode;
wire	RDM_oe_n;
wire	RDM_SCLK;
wire	RDM_test_async_load;
wire	RDM_test_loading;
wire	[3:0] RDM_test_state;
wire	RI_addr_clr;
wire	RI_addr_inc;
wire	RI_changing_mode;
wire	RI_cs_n;
wire	[7:0] RI_data_in;
wire	[7:0] RI_data_out;
wire	[1:0] RI_mode;
wire	RI_oe_n;
wire	RI_we_n;
reg	sreset;

assign	test_AM_start = 0;
assign	test_sm_state = 3'b000;




host_interface	b2v_Host_interface(
	.clk(clk),
	.sreset(sreset),
	.busy(HI_busy),
	.MISO(HI_MISO),
	.host_convst_start(host_convst_start),
	.host_rst_n(host_rst_n),
	.host_SCLK(host_SCLK),
	.host_MOSI(host_MOSI),
	.host_SS_n(host_SS_n),
	.host_mode(host_mode),
	.changing_mode(HI_changing_mode),
	.convst_start(HI_convst_start),
	.rst_n(HI_rst_n),
	.SCLK_(HI_SCLK),
	.MOSI(HI_MOSI),
	.SS_n(HI_SS_n),
	.host_busy(host_busy),
	.host_MISO(host_MISO),
	.mode(HI_mode));


RAM_interface	b2v_inst(
	.clk(clk),
	.sreset(sreset),
	.addr_clr(RI_addr_clr),
	.addr_inc(RI_addr_inc),
	.we_n(RI_we_n),
	.oe_n(RI_oe_n),
	.cs_n(RI_cs_n),
	.changing_mode(RI_changing_mode),
	.data_in(RI_data_in),
	.mode(RI_mode),
	.ram_data_bus(data_bus),
	.ram_we_n(ram_we_n),
	.ram_cs_n(ram_cs_n),
	.ram_oe_n(ram_oe_n),
	.data_out(RI_data_out),
	.ram_address(ram_address)
	);
	defparam	b2v_inst.N_BITS = 19;


always@(posedge clk)
begin
	begin
	sreset <= rst;
	end
end



acquisition_module	b2v_inst11(
	.clk(clk),
	.sreset(sreset),
	.start(HI_convst_start),
	.changing_mode(AM_changing_mode),
	.mode(HI_mode),
	.sdi(AM_adc_sdi),
	.sclk_(AM_adc_sclk),
	.convst(AM_adc_convst),
	.addr_inc(AM_addr_inc),
	.addr_clr(AM_addr_clr),
	.busy(AM_busy),
	.we_n(AM_we_n),
	.cs_n(AM_cs_n),
	.data(AM_data));
	defparam	b2v_inst11.samples = 3;


read_data_module	b2v_inst2(
	.clk(clk),
	.sreset(sreset),
	.changing_mode(RDM_changing_mode),
	.SCLK_(RDM_SCLK),
	.data(RDM_data),
	.mode(RDM_mode),
	
	.addr_inc(RDM_addr_inc),
	.oe_n(RDM_oe_n),
	.cs_n(RDM_cs_n),
	.MISO(RDM_MISO),
	.busy(RDM_busy)
	
	
	);


adc_interface	b2v_inst4(
	.clk(clk),
	.sreset(sreset),
	.changing_mode(AI_changing_mode),
	.rst_n(AI_rst_n),
	.convst(AI_convst),
	.sclk_(AI_sclk),
	.adc_rvs(adc_rvs),
	.adc_sdi(adc_sdi),
	.sdo(AI_sdo),
	.adc_convst(adc_convst),
	.adc_rst_n(adc_rst_n),
	.adc_sclk(adc_sclk),
	.adc_sdo(adc_sdo),
	.sdi(AI_sdi));



switch	b2v_inst6(
	.clk(clk),
	.sreset(sreset),
	.HI_changing_mode(HI_changing_mode),
	.HI_convst_start(HI_convst_start),
	.HI_rst_n(HI_rst_n),
	.HI_SCLK(HI_SCLK),
	.HI_MOSI(HI_MOSI),
	.HI_SS_n(HI_SS_n),
	.AM_adc_sclk(AM_adc_sclk),
	.AM_adc_convst(AM_adc_convst),
	.AM_addr_inc(AM_addr_inc),
	.AM_addr_clr(AM_addr_clr),
	.AM_busy(AM_busy),
	.AM_we_n(AM_we_n),
	.AM_cs_n(AM_cs_n),
	.RDM_addr_clr(RDM_addr_inc),
	.RDM_addr_inc(RDM_addr_inc),
	.RDM_oe_n(RDM_oe_n),
	.RDM_cs_n(RDM_cs_n),
	.RDM_MISO(RDM_MISO),
	.RDM_busy(RDM_busy),
	.AI_sdi(AI_sdi),
	.AM_data(AM_data),
	.HI_mode(HI_mode),
	.RI_data_out(RI_data_out),
	.HI_busy(HI_busy),
	.HI_MISO(HI_MISO),
	.RI_addr_clr(RI_addr_clr),
	.RI_addr_inc(RI_addr_inc),
	.RI_we_n(RI_we_n),
	.RI_oe_n(RI_oe_n),
	.RI_cs_n(RI_cs_n),
	.RI_changing_mode(RI_changing_mode),
	.AI_changing_mode(AI_changing_mode),
	.AI_rst_n(AI_rst_n),
	.AI_convst(AI_convst),
	.AI_sclk(AI_sclk),
	.AM_changing_mode(AM_changing_mode),
	.RDM_SCLK(RDM_SCLK),
	.RDM_changing_mode(RDM_changing_mode),
	.AI_sdo(AI_sdo),
	.AM_adc_sdi(AM_adc_sdi),
	.RDM_data(RDM_data),
	.RDM_mode(RDM_mode),
	.RI_data_in(RI_data_in),
	.RI_mode(RI_mode));

assign	test_addr_clr = AM_addr_clr;
assign	test_addr_inc = AM_addr_inc;
assign	test_running = AM_busy;
assign	test_AM_adc_sclk = AM_adc_sclk;
assign	test_AM_adc_convst = AM_adc_convst;

endmodule
