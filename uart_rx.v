module rx_serial_8 (
    input  wire        clk,
    input  wire        rst,       // reset síncrono
    input  wire         rx,        // dado serie
    output reg         busy_rx,      // está transmitindo
    output reg         done_rx,       // pulso de fim
	 output reg [7:0]   rx_reg

);    
	 
	  
    reg [3:0]  bit_cnt; // precisa contar até 9
	 
	 reg [9:0]  bit_time_cnt;
	 

    always @(posedge clk) begin
        if (rst) begin
            done_rx <= 1'b0;
            busy_rx   <= 1'b0;
				bit_time_cnt  <= 10'd0;
				bit_cnt <= 4'd0;
				rx_reg <= 8'd0;
        end
		  
        else begin
		 
            //Await one stop bit
            if (done_rx == 1'b1) begin
				
				    bit_time_cnt  <= bit_time_cnt + 10'd1;
					 //Next clock got to idle
					 if (bit_time_cnt == 10'd880) begin
					     bit_time_cnt  <= 10'd0;
						  done_rx <= 1'b0;
						  busy_rx <= 1'b0;
						  bit_cnt <= 4'd0;
					 end
					
				
				end
				
		      //State idle
            else if (rx == 1'd1 & !busy_rx) begin
				    //done_rx <= 1'b0;
		      end
				
				//Check start bit arriving
            else if (rx == 1'd0 & !busy_rx) begin
				    busy_rx   <= 1'b1;
		      end
				
				//UART reception on
            else if (busy_rx) begin
				    					 
					 bit_time_cnt  <= bit_time_cnt + 10'd1;
					 //Count bit time
					 if (bit_time_cnt == 10'd880) begin 
					 
                    bit_time_cnt  <= 10'd0;						  						  
						  
						  bit_cnt <= bit_cnt + 10'd1;
								
						  rx_reg[bit_cnt] <= rx;
						 						  
						  				  
						  if (bit_cnt == 10'd8) begin 
					 
                        //bit_cnt  <= 10'd0;
							   done_rx <= 1'b1;
							   //busy_rx <= 1'b0;
									 						      
						  end
								
								
					
					 end
					
					 					 					 
					 
		      end
				
		 
		  end //End of condition no reset
		  
    end
endmodule

		