module junction_58B (
    
    input  wire [383:0] phasor_data_in,   // dado paralelo
	 input  wire [95:0] temp_4_20_data_in,   // dado paralelo
    output [479:0] complete_data               // pulso de fim
	 
);    
localparam [95:0] data_empty = 96'h000000000000000000000000;

 assign complete_data = {data_empty, phasor_data_in};
	 
	 
endmodule