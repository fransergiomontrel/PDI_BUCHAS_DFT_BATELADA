module uart_tx_8 (

    input  wire        clk,
    input  wire        rst,       // reset síncrono
    input  wire        start,     // inicia transmissão
    output reg         tx,        // saída serial
    output reg         busy,      // está transmitindo
    output reg         done       // pulso de fim
	 
);    

	 localparam [7:0] data_in = 8'h01;
    	 
	 reg [1:0]  count_byte;
	 reg        done_start;
	 reg        stop_on;
	 reg        loaded;
    reg [7:0]  shift_reg; 
    reg [3:0]  bit_cnt;
	 reg [9:0]  tx_freq_divider;// register to calculate boud rate = 100MHz/tx_freq_divider
	 

    always @(posedge clk) begin
        if (rst) begin
            shift_reg <= 8'd0;
            bit_cnt   <= 4'd0;
            tx        <= 1'b1;
            busy      <= 1'b0;
            done      <= 1'b0;
				loaded    <= 1'b0;
				done_start <= 1'b0;
				stop_on <= 1'b0;
				count_byte <= 2'd0;
				tx_freq_divider  <= 10'd0;
				
        end 
        
		  else begin
				
				//tx <= 1'b1;
            // inicia transmissão
            if (start & !busy) begin                					 
					 
                bit_cnt   <= 4'd8;
					 
                busy      <= 1'b1;
					 
					 tx <= 1'b1;
					 
					 tx_freq_divider  <= 10'd0;
					 
					 if (!loaded) begin
				        shift_reg <= data_in;
						  loaded <= 1'b1;
				    end
					 
            end
				
				else if (busy & !done_start) begin
				//Bit de start durante 868*(Tck)
				    tx_freq_divider  <= tx_freq_divider + 10'd1;
					 if (tx_freq_divider == 10'd868) begin
					     done_start <= 1'b1;
						  tx_freq_divider  <= 10'd0;
						  tx <= shift_reg[0];
					 end
				
				end
			    
            // transmissão em andamento
            else if (busy & done_start & !stop_on) begin
				    tx_freq_divider  <= tx_freq_divider + 10'd1;
					 tx <= shift_reg[0];        // envia LSB
					 					 
					 if (tx_freq_divider == 10'd868) begin //boud rate
                    
                    shift_reg <= shift_reg >> 1;      // shift
                    bit_cnt   <= bit_cnt - 1;
						  tx_freq_divider  <= 10'd0;
						  
						  if (bit_cnt == 1) begin
                    
						      stop_on <= 1'b1;
						  
						      tx   <= 1'b1;
						  
						      tx_freq_divider  <= 10'd0;
						  
						      done <= 1'b1;
								
								busy <= 1'b0;
								
								bit_cnt <= 4'd8;
						  
                    end					 
						  
					 end					 
					 
            end
				
				
        end
    end

endmodule