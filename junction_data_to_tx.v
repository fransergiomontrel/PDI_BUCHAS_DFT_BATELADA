module junction_58B (
    
    input  wire [383:0] phasor_data_in,   // dado paralelo
	 input  wire [79:0] temp_4_20_data_in,   // dado paralelo
    
    output [463:0] complete_data               // pulso de fim
	 

);    

 assign complete_data = {temp_4_20_data_in, phasor_data_in};
	 
	 
endmodule