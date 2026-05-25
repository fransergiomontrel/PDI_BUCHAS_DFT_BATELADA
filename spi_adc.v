module spi_adc (

    input  wire        clk,
    input  wire        rst,       // reset síncrono
	 input [31:0] config_reg, 
	 output reg         sclk,
	 output reg         ncs,
	 output reg         mosi       // PINO DE OUTPUT DO MESTRE
	 
);    
	  
	 reg [5:0]  bit_cnt;
	 reg [7:0]  div_sclk;
	 reg [1:0]  delay;
	 reg [31:0] shift_reg;
	 reg [5:0] active_period;
	 reg [2:0] samples;
	 
	 // Definição dos estados (Verilog clássico)
    localparam NO_MOSI_DATA = 4'b0000;
	 localparam CHIP_SELECTED = 4'b0001;
	 localparam TSU_CSCK_MOSI = 4'b0010;
	 localparam AWAIT_SCLK_FALL_MOSI = 4'b0011;
	 localparam AWAIT_SCLK_RISE_MOSI = 4'b0100;
	 localparam THT_CKCS_MOSI = 4'b0101;
	 localparam IDLE = 4'b0110;
	 
	 /*
	 localparam TIME_CONVERSION = 4'b0110;
	 localparam TSU_CSCK_MISO = 4'b0111;
	 localparam AWAIT_SCLK_FALL_MISO = 4'b1000;
	 localparam AWAIT_SCLK_RISE_MISO = 4'b1001;
	 localparam THT_CKCS_MISO = 4'b1010;
	 localparam NEXT_CONVERSION = 4'b1011;
	 localparam IDLE = 4'b1100;
	 */
	 
	 reg [3:0] current_spi_state;
	 
	 
	 always @(posedge clk) begin
	 
	 
	 if (rst) begin
	 
            sclk <= 1'b0;
            ncs <= 1'b1;
				mosi <= 1'b0;
				div_sclk <= 8'd0;
				delay <= 2'd0;
				bit_cnt <= 6'd31;
				active_period <= 6'd0;
				samples <= 3'd0; 
				
				current_spi_state <= NO_MOSI_DATA;
				
        end
	 
	 else begin
	 
	 case (current_spi_state)
		
        NO_MOSI_DATA:
			  
			   begin
			       if (config_reg == 32'd0) begin
					     current_spi_state <= NO_MOSI_DATA;
                end
					 
					 else begin
					 
                	  current_spi_state <= CHIP_SELECTED;
						  ncs <= 1'b0;
						  
                end
					 			              
				end
				
		  CHIP_SELECTED:
			  
			   begin
			      
			       current_spi_state <= TSU_CSCK_MOSI;
                /*real design begin*/
					 shift_reg <= config_reg;
			              
		      end
			
			TSU_CSCK_MOSI:
			  
			   begin
			      
			       delay  <= delay + 2'd1;
					 //20 ns to satisfy delay between nCS falling and first SCLK rising
					 if (delay == 2'd1) begin
					     delay <= 2'd0;
						  current_spi_state <= AWAIT_SCLK_FALL_MOSI;
						  mosi <= shift_reg[31];
						  sclk <= 1'b1;
					 end   					 
			       else begin
					 
					     current_spi_state <= TSU_CSCK_MOSI;
						  
					 end   					       
		      end
				
		 AWAIT_SCLK_FALL_MOSI:
			  
			  begin
			      
					div_sclk  <= div_sclk + 8'd1;
					//await 1 us to low sclk based on fsclk = 500 kHz
					if (div_sclk == 8'd49) begin
					    div_sclk <= 8'd0;
						 sclk <= 1'b0;
						 shift_reg <= shift_reg << 1;
						 bit_cnt <= bit_cnt - 1;
						 if (bit_cnt == 6'd0) begin
						     current_spi_state <= THT_CKCS_MOSI;
							  bit_cnt <= 6'd31;
							  mosi <= 1'b0;
						 end
						 else begin
						     current_spi_state <= AWAIT_SCLK_RISE_MOSI;
						 end
						  					  
					end
					 
					else begin
					    current_spi_state <= AWAIT_SCLK_FALL_MOSI;
					end
			       		       
		      end
				
		 AWAIT_SCLK_RISE_MOSI:
			  
			  begin
			      
					div_sclk  <= div_sclk + 8'd1;
					//await 1 us to low sclk based on fsclk = 500 kHz
					if (div_sclk == 8'd49) begin
					    sclk <= 1'b1;
						 div_sclk <= 8'd0;
						 mosi <= shift_reg[31];
						 current_spi_state <= AWAIT_SCLK_FALL_MOSI;
					end
					else begin
					    current_spi_state <= AWAIT_SCLK_RISE_MOSI;
					end
			       		       
		     end
				
		THT_CKCS_MOSI:
			  
			 begin
			      
			     delay  <= delay + 2'd1;
				  //20 ns to satisfy delay between SCLK falling and nCS rising 
				  if (delay == 2'd1) begin
					   delay <= 2'd0;
						ncs <= 1'b1;
						
						current_spi_state <= IDLE;
						  
				  end
				  
			     else begin					 
					   
					   current_spi_state <= THT_CKCS_MOSI;
						  
				  end   					       
		    end
			 
		IDLE:
			  
			 begin
			   					
			     current_spi_state <= IDLE;
						  
		    end
			 
		/*		
		TIME_CONVERSION:
			  
			 begin
			     
				  active_period  <= active_period + 6'd1;
				  ncs <= 1'b1;
				  if (active_period == 6'd34) begin
					   active_period  <= 6'd0;
						
						ncs <= 1'b0;
						
						current_spi_state <= TSU_CSCK_MISO;
						  
				  end
				  
			     else begin					 
					   
					   current_spi_state <= TIME_CONVERSION;
						  
				  end   					       
				  						 				 
			       		       
		    end
			 
		TSU_CSCK_MISO:
			  
			   begin
			      
			       delay  <= delay + 2'd1;
					 //20 ns to satisfy delay between nCS falling and first SCLK rising
					 if (delay == 2'd1) begin
					     delay <= 2'd0;
						  current_spi_state <= AWAIT_SCLK_FALL_MISO;
						  sclk <= 1'b1;
					 end   					 
			       else begin
					 
					     current_spi_state <= TSU_CSCK_MISO;
						  
					 end   					       
		      end
				
		 AWAIT_SCLK_FALL_MISO:
			  
			  begin
			      
					div_sclk  <= div_sclk + 8'd1;
					//await 1 us to low sclk based on fsclk = 500 kHz
					if (div_sclk == 8'd49) begin
					    div_sclk <= 8'd0;
						 sclk <= 1'b0;
						 bit_cnt <= bit_cnt - 1;
						 if (bit_cnt == 6'd16) begin
						     current_spi_state <= THT_CKCS_MISO;
							  bit_cnt <= 6'd31;
							  
						 end
						 else begin
						     current_spi_state <= AWAIT_SCLK_RISE_MISO;
						 end
						  					  
					end
					 
					else begin
					    current_spi_state <= AWAIT_SCLK_FALL_MISO;
					end
			       		       
		      end
				
		 AWAIT_SCLK_RISE_MISO:
			  
			  begin
			      
					div_sclk  <= div_sclk + 8'd1;
					//await 1 us to low sclk based on fsclk = 500 kHz
					if (div_sclk == 8'd49) begin
					    sclk <= 1'b1;
						 div_sclk <= 8'd0;
						 current_spi_state <= AWAIT_SCLK_FALL_MISO;
					end
					else begin
					    current_spi_state <= AWAIT_SCLK_RISE_MISO;
					end
			       		       
		     end
				
		THT_CKCS_MISO:
			  
			 begin
			      
			     delay  <= delay + 2'd1;
				  //20 ns to satisfy delay between SCLK falling and nCS rising 
				  if (delay == 2'd1) begin
					   delay <= 2'd0;
						ncs <= 1'b1;
						
						current_spi_state <= NEXT_CONVERSION;
						  
				  end
				  
			     else begin					 
					   
					   current_spi_state <= THT_CKCS_MISO;
						  
				  end   					       
		    end		
			
		NEXT_CONVERSION:
			  
			 begin
			     samples <= samples + 3'd1;
				  if (samples < 3'd4) begin
				      current_spi_state <= TIME_CONVERSION;
				  end
				  else begin
				      current_spi_state <= IDLE;
						samples <= 3'd0;
				  end
						  				     
		    end		

		IDLE:
		
		    begin 
			     current_spi_state <= IDLE;	  				     
		    end		
	 */
	  endcase 
	 	 	 
	 end
	   	          		  
 end
	 
	 
endmodule
	 
	 
	 
       