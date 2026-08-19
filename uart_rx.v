module rx_serial_8 (

    input  wire        clk,
    input  wire        rst,       
    input  wire        rx,        
    output reg         busy_rx,      
    output reg         done_rx,     
	 output reg [7:0]   rx_reg,
	 output wire error

);    

	 //8 bits size register to count 8 bits of data
    reg [3:0]  bit_cnt; 
	 //10 bits size register to count period of boud between bits
	 reg [9:0]  bit_time_cnt;
	 //1 bit size register to notice state of all bits data received
	 reg byte_received;
	 
    always @(posedge clk) begin
	 
        if (rst) begin
            done_rx <= 1'b0;
            busy_rx   <= 1'b0;
				bit_time_cnt  <= 10'd0;
				bit_cnt <= 4'd0;
				rx_reg <= 8'd0;
				byte_received <= 1'b0;
        end
		  
        else begin
				
				//State idle
            if (rx == 1'd1 & !busy_rx) begin
				
				    done_rx <= 1'b0;
					 			 
		      end
				
				//Check start bit arriving
            else if (rx == 1'd0 & !busy_rx) begin
				
				    busy_rx <= 1'b1;
					 
		      end
				
				//UART reception on
            else if (busy_rx & !byte_received) begin
				    					 
					 bit_time_cnt  <= bit_time_cnt + 10'd1;
					 //Count bit time
					 if (bit_time_cnt == 10'd900) begin 
					 
                    bit_time_cnt  <= 10'd0;						  						  					  
						  bit_cnt <= bit_cnt + 10'd1;
						  				  
						  if (bit_cnt == 10'd7) begin 
								
								bit_cnt <= 10'd0;
								byte_received <= 1'b1;
							   									 						      
						  end
						  else begin 
					 
							   rx_reg[bit_cnt] <= rx;
								
							   									 						      
						  end
																					
					 end										 					 					 
					 
		      end				
				
           //Await one stop bit finish
           else if (byte_received == 1'b1) begin
				
				    bit_time_cnt  <= bit_time_cnt + 10'd1;
					 if (bit_time_cnt == 10'd900) begin
					 
					     bit_time_cnt  <= 10'd0;
						  
						  done_rx <= 1'b1;
						  busy_rx <= 1'b0;
						  byte_received <= 1'b0;
						  						  
					 end
					 
			  end
						 
		  end //End of condition no reset
		  
    end
	 
endmodule

		