module crc16_ccitt_10bytes(

    input wire [79:0] data_in,
	 
	 output wire [95:0] crc_data 
    
);

reg [15:0] crc_out;

function [15:0] crc16_ccitt_false;

    input [79:0] data;
	 integer i;
	 reg[15:0] crc;
	 reg bit_in;
	 
begin

    crc = 16'hFFFF;
	 
	 for (i = 79; i >= 0; i = i -1) begin
	 
	     bit_in = data[i] ^ crc[15];
		  crc = {crc[14:0], 1'b0};
		  
		  if (bit_in) begin
		      crc = crc ^ 16'h1021;
		  end
	 
	 end
	 
	 crc16_ccitt_false = crc;
	 
	 end
	 
	 endfunction

    assign crc_data = { crc16_ccitt_false(data_in), data_in };

endmodule