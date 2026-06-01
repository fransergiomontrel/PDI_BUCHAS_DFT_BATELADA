module uart_tx (
    input  wire        clk,
    input  wire        rst,       // reset síncrono
    input  wire        start,     // inicia transmissão
    input  wire [479:0] data_in,   // dado paralelo
    output reg         tx,        // saída serial
    output reg         busy,      // está transmitindo
    output reg         done       // pulso de fim	 

);    

	 //localparam [383:0] data_in = 384'hABCD788C498308570E0A788C498308570E0A788C498308570E0A788C498308570E0A788C498308570E0A788C49830B12;
	 wire [59:0] parity_odd;
	 assign parity_odd = 
	 { ^data_in[7:0], ^data_in[15:8], ^data_in[23:16], ^data_in[31:24], ^data_in[39:32],
	   ^data_in[47:40], ^data_in[55:48], ^data_in[63:56], ^data_in[71:64], ^data_in[79:72],
		^data_in[87:80], ^data_in[95:88], ^data_in[103:96], ^data_in[111:104], ^data_in[119:112],
		^data_in[127:120], ^data_in[135:128], ^data_in[143:136], ^data_in[151:144], ^data_in[159:152],
		^data_in[167:160], ^data_in[175:168], ^data_in[183:176], ^data_in[191:184], ^data_in[199:192],
		^data_in[207:200], ^data_in[215:208], ^data_in[223:216], ^data_in[231:224], ^data_in[239:232],
		^data_in[247:240], ^data_in[255:248], ^data_in[263:256], ^data_in[271:264], ^data_in[279:272],
		^data_in[287:280], ^data_in[295:288], ^data_in[303:296], ^data_in[311:304], ^data_in[319:312],
		^data_in[327:320], ^data_in[335:328], ^data_in[343:336], ^data_in[351:344], ^data_in[359:352],
		^data_in[367:360], ^data_in[375:368], ^data_in[383:376], ^data_in[391:384], ^data_in[399:392],
		^data_in[407:400], ^data_in[415:408], ^data_in[423:416], ^data_in[431:424], ^data_in[439:432],
		^data_in[447:440], ^data_in[455:448], ^data_in[463:456], ^data_in[471:464], ^data_in[479:472]}; 
								  
	 reg [5:0]  count_byte;
    reg [479:0] shift_reg; 
    reg [3:0]  bit_cnt; // precisa contar até 32
	 reg [9:0]  tx_freq_divider;// register to calculate boud rate = 100MHz/tx_freq_divider
	 
	 //States definition for states machine of UART 8E1 for 60 bytes
	 
    localparam START = 3'b000;//
	 localparam START_BIT = 3'b001;//
	 localparam DATA_BITS = 3'b010;//
	 localparam PARITY_BIT = 3'b011;//
	 localparam STOP_BIT = 3'b100;//
	 
	 reg [2:0] state_uart_tx;
	 
    always @(posedge clk) begin
        if (rst) begin
		  
            shift_reg <= 480'd0;
            bit_cnt   <= 4'd0;
            tx        <= 1'b1;
            busy      <= 1'b0;
            done      <= 1'b0;
				count_byte <= 6'd0;
				tx_freq_divider  <= 10'd0;			
				state_uart_tx <= START;
				
        end
		  
        else begin
		  
				done <= 1'b0;
				
				case (state_uart_tx)			  
	
			   START:
			  
			   begin
						 
				    if (start) begin                					 
					 
                    bit_cnt   <= 4'd8;
                    busy      <= 1'b1;
					     tx <= 1'b0;
					     tx_freq_divider  <= 10'd0;
				        shift_reg <= data_in;						 
					     state_uart_tx <= START_BIT;
					 
                end
						 
				end
				
				START_BIT:
			  
			   begin
						 
				    //Bit de start durante 868*(Tck)
				    tx_freq_divider  <= tx_freq_divider + 10'd1;
					 if (tx_freq_divider == 10'd868) begin
						 
						  tx_freq_divider  <= 10'd0;
						  tx <= shift_reg[0];
						  bit_cnt   <= bit_cnt - 1;
						  state_uart_tx <= DATA_BITS;
							  
					 end
						 
				end
				
				DATA_BITS:
				
				begin
				
				    //Data transmitting goes on            
				    tx_freq_divider  <= tx_freq_divider + 10'd1;
					 tx <= shift_reg[0];        // envia LSB
					 					 
					 if (tx_freq_divider == 10'd868) begin //boud rate
					 
						  if (bit_cnt == 0) begin
								
						  		bit_cnt   <= 4'd8;
								shift_reg <= shift_reg >> 1;
								tx_freq_divider  <= 10'd0;
								tx <= parity_odd[count_byte];
								state_uart_tx <= PARITY_BIT;
								
						  end
						  
						  else begin
						  
								bit_cnt   <= bit_cnt - 1;
                        shift_reg <= shift_reg >> 1;
						      tx_freq_divider  <= 10'd0;
								state_uart_tx <= DATA_BITS;
								
						  end
						  
					 end					 
					 								
				end
				
				PARITY_BIT:
				
				begin
				    //Sending parity bit           
				    tx_freq_divider  <= tx_freq_divider + 10'd1;					 					 
					 if (tx_freq_divider == 10'd868) begin //boud rate
                    
						  tx_freq_divider  <= 10'd0;
						  tx <= 1'b1;
						  count_byte <= count_byte + 1;
						  state_uart_tx <= STOP_BIT;
						  
					 end					 			
				
				end
			    
				STOP_BIT:
				
				begin
				
				    tx_freq_divider  <= tx_freq_divider + 10'd1;					 
					 if (tx_freq_divider == 10'd868) begin //boud rate
					 		  
						  tx_freq_divider  <= 10'd0;
						  
						  if (count_byte == 6'd60) begin
						  
						      done <= 1'b1;
						      count_byte <= 6'd0;
								busy <= 1'b0;
								state_uart_tx <= START;
								
						  end
						  else begin
						  
						      //New start bit
								tx <= 1'b0;
								state_uart_tx <= START_BIT;
								
						  end
						 
					 end
				end				
				
        endcase
		  
    end
end

endmodule