module produto_modulo(
    input wire clk,
	 input wire reset,
	 input wire [15:0] data,
	 input wire [15:0] luts,
	 output wire [31:0] dft_component, 
	 input product_on
);

wire mult_clken;
wire mult_aclr;

assign mult_clken = !reset & product_on;
assign mult_aclr = reset;

lpm_mult #(
    .lpm_widtha(16),
	 .lpm_widthb(16),
	 .lpm_widthp(32),
	 .lpm_representation("UNSIGNED"),
	 .lpm_pipeline(1)
)u_mult (
    .dataa(data),
	 .datab(luts),
	 .result(dft_component),
	 .clock(clk),
	 .clken(mult_clken),
	 .aclr(mult_aclr)

);
endmodule