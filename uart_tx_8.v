module uart_tx_8 (
    input  wire        clk,
    input  wire        rst,       // reset síncrono
    input  wire        start,     // inicia transmissão
    input  wire [7:0] data_in,   // dado paralelo
    output reg         tx,        // saída serial
    output reg         busy,      // está transmitindo
    output reg         done       // pulso de fim	 

);    

    reg [3:0]  bit_cnt; // precisa contar até 32
	 reg [9:0]  tx_freq_divider;// register to calculate boud rate = 100MHz/tx_freq_divider
	 
	 //States definition for states machine of UART 8E1 for 60 bytes 
    localparam START = 3'b00;//
	 localparam START_BIT = 3'b01;//
	 localparam DATA_BITS = 3'b10;//
	 localparam STOP_BIT = 3'b11;//
	 
	 reg [1:0] state_uart_tx;
	 
    always @(posedge clk) begin
        if (rst) begin
		  
            bit_cnt   <= 4'd0;
            tx        <= 1'b1;
            busy      <= 1'b0;
            done      <= 1'b0;
				tx_freq_divider  <= 10'd0;			
				state_uart_tx <= START;
				
        end
		  
        else begin
		  
				done <= 1'b0;
				
				case (state_uart_tx)			  
	
			   START:
			  
			   begin
						 
				    if (start) begin                					 
					 
                    busy      <= 1'b1;
					     tx <= 1'b0;
					     tx_freq_divider  <= 10'd0;					 
					     state_uart_tx <= START_BIT;
					 
                end
						 
				end
				
				START_BIT:
			  
			   begin
						 
				    //Bit de start durante 868*(Tck)
				    tx_freq_divider  <= tx_freq_divider + 10'd1;
					 if (tx_freq_divider == 10'd868) begin
						 
						  tx_freq_divider  <= 10'd0;
						  tx <= data_in[bit_cnt];
						  state_uart_tx <= DATA_BITS;
							  
					 end
						 
				end
				
				DATA_BITS:
				
				begin
				
				    //Data transmitting goes on            
				    tx_freq_divider  <= tx_freq_divider + 10'd1;
					 tx <= data_in[bit_cnt];        // envia LSB
					 					 
					 if (tx_freq_divider == 10'd868) begin //boud rate
					 
						  if (bit_cnt == 7) begin
								
						  		bit_cnt   <= 4'd0;
								tx_freq_divider  <= 10'd0;
								tx <= 1'b1;
								state_uart_tx <= STOP_BIT;
								
						  end
						  
						  else begin
						  
								bit_cnt   <= bit_cnt + 1;
						      tx_freq_divider  <= 10'd0;
								
						  end
						  
					 end					 
					 								
				end
			    
				STOP_BIT:
				
				begin
				    
				    tx_freq_divider  <= tx_freq_divider + 10'd1;					 
					 if (tx_freq_divider == 10'd868) begin //boud rate
						
						  tx_freq_divider  <= 10'd0;
						  done <= 1'b1;
						  busy <= 1'b0;
						  state_uart_tx <= START;
						 
					 end
				end				
				
        endcase
		  
    end
end

endmodule