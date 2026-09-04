module uart_tx (
    input  wire        clk,
    input  wire        rst,       // reset síncrono
    input  wire        start,     // inicia transmissão
    input  wire [383:0] data_in,   // dado paralelo
    output reg         tx,        // saída serial
    output reg         busy,      // está transmitindo
    output reg         done       // pulso de fim	 

);    

	 //localparam [383:0] data_in = 384'hABCD788C498308570E0A788C498308570E0A788C498308570E0A788C498308570E0A788C498308570E0A788C49830B12;
	 integer i;
	 reg [15:0] sum_reg;
	 
	 always @(*) begin
	 
	     sum_reg = 16'd0;
		  for (i = 0; i < 48; i = i +1) begin
		      sum_reg = sum_reg + data_in[(i*8) +: 8];
		  end
	 
	 end
	 
	 wire [7:0] chksum_low;
	 wire [7:0] chksum_high;
	 
	 assign chksum_low = sum_reg[7:0] | 8'h80;
	 assign chksum_high = sum_reg[15:8] | 8'h80;
	 
	 reg start_8_ctl;
    reg [7:0] byte_to_send;
	 wire done_8_ctl;
	 wire tx_8;
	 
	  uart_tx_8 u_uart_tx_8(
	  
	  .clk(clk),
     .rst(rst),       
     .start(start_8_ctl),
	  .data_in(byte_to_send),
     .tx_out(tx_8),        
     .busy_out(),      
     .done_out(done_8_ctl)	  
	  
);

	 
	 reg [5:0]  count_byte;
    reg [479:0] shift_reg; 
    reg [3:0]  bit_cnt; // precisa contar até 32
	 reg [9:0]  tx_freq_divider;// register to calculate boud rate = 100MHz/tx_freq_divider
	 
	 //States definition for states machine of UART 8E1 for 60 bytes
	 
    localparam START = 4'b0000;//
	 localparam BYTE_START = 4'b0001;//
	 localparam BYTE_TYPE = 4'b0010;//
	 //localparam START = 3'b000;//
	 localparam START_BIT = 4'b0011;//
	 localparam DATA_BITS = 4'b0100;//
	 localparam STOP_BIT = 4'b0101;//
	 localparam BYTE_END = 4'b0110;//
	 localparam CHKSUM_LOW = 4'b0111;//
	 localparam CHKSUM_HIGH = 4'b1000;//
	 
	 reg [3:0] state_uart_tx;
	 
    always @(posedge clk) begin
        if (rst) begin
		  
            shift_reg <= 384'd0;
            bit_cnt   <= 4'd0;
            tx        <= 1'b1;
            busy      <= 1'b0;
            done      <= 1'b0;
				count_byte <= 6'd0;
				tx_freq_divider <= 10'd0;
				byte_to_send <= 8'h00;
				start_8_ctl <= 1'b0;
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
					     //tx <= 1'b0;
					     tx_freq_divider  <= 10'd0;
				        shift_reg <= data_in;
						  byte_to_send <= 8'h01;
					     start_8_ctl <= 1'b1;
					     state_uart_tx <= BYTE_START;
					 
                end
						 
				end
				
				BYTE_START:
			  
			   begin
				
				   tx <= tx_8;
					start_8_ctl <= 1'b0;
					if (done_8_ctl == 1'b1) begin
					
						 byte_to_send <= 8'h18;
					    start_8_ctl <= 1'b1;
					    state_uart_tx <= BYTE_TYPE;
				       
					end
						 
				end
				
				BYTE_TYPE:
			  
			   begin
				
				   tx <= tx_8;
					start_8_ctl <= 1'b0;
					
					if (done_8_ctl == 1'b1) begin
					    tx <= 1'b0;
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
								tx <= 1'b1;
								state_uart_tx <= STOP_BIT;
								
						  end
						  
						  else begin
						  
								bit_cnt   <= bit_cnt - 1;
                        shift_reg <= shift_reg >> 1;
						      tx_freq_divider  <= 10'd0;
								state_uart_tx <= DATA_BITS;
								
						  end
						  
					 end					 
					 								
				end
			    
				STOP_BIT:
				
				begin
				
				    tx_freq_divider  <= tx_freq_divider + 10'd1;					 
					 if (tx_freq_divider == 10'd868) begin //boud rate
					 		  
						  tx_freq_divider  <= 10'd0;
						  
						  if (count_byte == 6'd47) begin
						  
						      //done <= 1'b1;
						      count_byte <= 6'd0;
								busy <= 1'b0;
								byte_to_send <= 8'h04;
					         start_8_ctl <= 1'b1;
								state_uart_tx <= BYTE_END;
								
						  end
						  else begin
						      //New start bit
								count_byte <= count_byte + 6'd1;
								tx <= 1'b0;
								state_uart_tx <= START_BIT;
								
						  end
						 
					 end
				end

				BYTE_END:
			 
			   begin
				
				   tx <= tx_8;
					start_8_ctl <= 1'b0;
					if (done_8_ctl == 1'b1) begin
					
						 byte_to_send <= chksum_low;
					    start_8_ctl <= 1'b1;
					    state_uart_tx <= CHKSUM_LOW;
				       
					end
						 
				end
				
			   CHKSUM_LOW:
			  
			   begin
				
				   tx <= tx_8;
					start_8_ctl <= 1'b0;
					if (done_8_ctl == 1'b1) begin
					
						 byte_to_send <= chksum_high;
					    start_8_ctl <= 1'b1;
					    state_uart_tx <= CHKSUM_HIGH;
				       
					end
						 
				end
				
				CHKSUM_HIGH:
			  
			   begin
				
				   tx <= tx_8;
					start_8_ctl <= 1'b0;
					if (done_8_ctl == 1'b1) begin
					    done <= 1'b1;
					    state_uart_tx <= START;
				       
					end
						 
				end
				
        endcase
		  
    end
end

endmodule