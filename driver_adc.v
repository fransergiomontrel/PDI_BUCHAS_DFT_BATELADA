module driver_ADS8691 (

    input  wire  clk,
    input  wire  rst,       // reset síncrono
	 input wire restart,
	 output driver_ncs,
	 output driver_sclk,
	 output driver_mosi	 
    	 
);

   reg [31:0]   driver_config_reg;
	
	 
	 spi_adc u_spi_adc(
	 
    .clk(clk),
    .rst(rst),       // reset síncrono
	 .restart(restart),
	 .sclk(driver_sclk),
	 .ncs(driver_ncs),
	 .mosi(driver_mosi),       // PINO DE OUTPUT DO MESTRE
	 .config_reg(driver_config_reg)

);

 // Definição dos estados (Verilog clássico)
    localparam START_ADC = 2'b00;
	 localparam CONFIG = 2'b01;
	 localparam IDLE_ADC = 2'b10;
	 
	 reg [1:0] driver8691_state;    
	 
	always @(posedge clk) begin
							 							 	    
		 if(rst) begin
		     driver_config_reg <= 32'h00000000;
			  driver8691_state <= START_ADC;
		 end
		 
		 else begin
				
		     case (driver8691_state)
		
               START_ADC:
			  
			      begin
							 	 		
						driver8691_state <= CONFIG;
						driver_config_reg <= 32'hD0140040;
									  
				   end
				
			
					CONFIG:
					  
					begin
							 
					if (driver_ncs == 1'b0) begin		
					
						 driver8691_state <= CONFIG;	
							  
					end
							 
					else begin					
					
						 driver8691_state <= IDLE_ADC;
						 
					end
								 				 
					end
				
				IDLE_ADC:
			  
			   begin
							 	 		
					if (restart == 1'b1) begin							 
						 driver8691_state <= START_ADC;								 
					end
									  
				 end
						  
	        endcase 
			 
		 end 
		 
	end
	
endmodule
