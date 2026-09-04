module driver_ADS1118 (

    input  wire  clk,
    input  wire  rst,       // reset síncrono
	 output driver_ncs,
	 output driver_sclk,
	 output driver_mosi,
	 input  driver_miso,
	 output [79:0] driver_data_out,
	 input wire acquire_again
	 
);


   reg [15:0]   driver_config_reg;
	/*(* noprune *)*/ wire [15:0]   driver_data_reg;
	wire  driver_done_miso;
	//Array of data registers
	reg [15:0] array_data[0:4];
	
	//ASSIGN ADS1118 TO DRIVER OUTPUT
	assign driver_data_out = {
	
	array_data[4],
	array_data[3],
	array_data[2],
	array_data[1],
	array_data[0]
	
	};
	
	
	reg [1:0] shift_temp;
   
   reg          loaded;	
	 
	 spi_4_20 u_spi_4_20(
    .clk(clk),
    .rst(rst),       // reset síncrono
	 .sclk(driver_sclk),
	 .ncs(driver_ncs),
    .miso(driver_miso),      // PINO DE INPUT DO MESTRE
	 .mosi(driver_mosi),       // PINO DE OUTPUT DO MESTRE
	 .config_reg(driver_config_reg),      
	 .data_reg(driver_data_reg),
	 .done_miso(driver_done_miso)

);

 // Definição dos estados (Verilog clássico)
    localparam IDLE_4_20 = 4'b0000;
	 localparam SET_CHANNEL_0 = 4'b0001;
	 localparam GET_CHANNEL_0 = 4'b0010;
	 localparam SET_CHANNEL_1 = 4'b0011;
	 localparam GET_CHANNEL_1 = 4'b0100;
	 localparam SET_CHANNEL_2 = 4'b0101;
	 localparam GET_CHANNEL_2 = 4'b0110;
	 localparam SET_CHANNEL_3 = 4'b0111;
	 localparam GET_CHANNEL_3 = 4'b1000;
	 localparam SET_TEMP = 4'b1001;
	 localparam GET_TEMP = 4'b1010;
	 localparam SHIFT_TEMP = 4'b1011;
	 
	 reg [3:0] driver1118_state;    
	 
  
    	 
	always @(posedge clk) begin
							 							 	    
		 if(rst) begin
			  array_data[4] <= 16'd0;
			  array_data[3] <= 16'd0;
			  array_data[2] <= 16'd0;
			  array_data[1] <= 16'd0;
			  array_data[0] <= 16'd0;
		     driver_config_reg <= 16'h0000;
			  loaded <= 1'b0;
			  shift_temp <= 2'b00;
		 end
		 
		 else begin
				
		     case (driver1118_state)
		
               IDLE_4_20:
			  
			          begin
							 
							 if (!loaded | acquire_again) begin							 
								  loaded <= 1'b1;
								  driver1118_state <= SET_CHANNEL_0;								 
							 end
							 
							 else begin							 
								  driver1118_state <= IDLE_4_20;								 
							 end
					 			              
				       end
				
			
					SET_CHANNEL_0:
					  
						 begin
							 
							  driver_config_reg <= 16'h448A;
							  if (driver_done_miso == 1'b1) begin
							      driver1118_state <= GET_CHANNEL_0;    
							  end
							  else begin
							      driver1118_state <= SET_CHANNEL_0;
							  end
							  
												 
						 end
				
					GET_CHANNEL_0:
						  
						 begin
							 
							  array_data[0] <= driver_data_reg;
							  driver1118_state <= SET_CHANNEL_1;
							  
						 end
								
					SET_CHANNEL_1:
						  
						 begin
								
							  driver_config_reg <= 16'h548A;
							  if (driver_done_miso == 1'b1) begin
							      driver1118_state <= GET_CHANNEL_1;    
							  end
							  else begin
							      driver1118_state <= SET_CHANNEL_1;
							  end
												 
						 end
						
					GET_CHANNEL_1:
						  
						 begin
								
							  array_data[1] <= driver_data_reg;
							  driver1118_state <= SET_CHANNEL_2; 
												 
						 end		
						
					SET_CHANNEL_2:
						  
						 begin
								
							  driver_config_reg <= 16'h648A;
							  if (driver_done_miso == 1'b1) begin
							      driver1118_state <= GET_CHANNEL_2;    
							  end
							  else begin
							      driver1118_state <= SET_CHANNEL_2;
							  end	
								 
												 
						 end
							
					GET_CHANNEL_2:
						  
						 begin
								
							  array_data[2] <= driver_data_reg;
							  driver1118_state <= SET_CHANNEL_3;
								 
												 
						 end
					 
					SET_CHANNEL_3:
						  
						 begin
								
					        driver_config_reg <= 16'h748A;
							  if (driver_done_miso == 1'b1) begin
							      driver1118_state <= GET_CHANNEL_3;    
							  end
							  else begin
							      driver1118_state <= SET_CHANNEL_3;
							  end	
								 
												 
						 end
						 
					GET_CHANNEL_3:
						  
						 begin
								
							  array_data[3] <= driver_data_reg;
							  driver1118_state <= SET_TEMP;
								 
												 
						 end
			 
					 SET_TEMP:
							  
						  begin
									
								driver_config_reg <= 16'h049A;
							  if (driver_done_miso == 1'b1) begin
							      driver1118_state <= GET_TEMP;    
							  end
							  else begin
							      driver1118_state <= SET_TEMP;
							  end	
									 
													 
						  end
								
					 GET_TEMP:
							  
						  begin
									
								array_data[4] <= driver_data_reg;
								
								driver1118_state <= SHIFT_TEMP;									
													 
						  end
						  
					 SHIFT_TEMP:
						  begin
								//TO DO TWO RIGHT SHIFT
						      shift_temp <= shift_temp + 1;
								array_data[4] <= array_data[4] >> 1;
								if (shift_temp == 2'b01) begin
								    shift_temp <= 2'b00;
									 driver1118_state <= IDLE_4_20;
									 loaded <= 1'b1;
								end
								else begin
								    driver1118_state <= SHIFT_TEMP;
								end
								
						  end
						  
	        endcase 
			 
		 end 
		 
	end
	
endmodule