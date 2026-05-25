module slaver_states (

    input  wire clk,
	 input  wire rst_hardware,
    output reg  rst,
	 output wire tx,
	 output reg convst,
	 output wire host_mosi,
	 output wire host_sclk,
	 //output reg [1:0] select,
	 output reg select0_1,
	 output reg select1_1
	 
);    
	 	  
    reg [23:0]  delay;
	 reg start_8_ctl;
	 reg tx_B;
	 
	 reg reset_adc_config;
	 wire ncs_adc_config;
	 wire mosi_adc_config;
	 wire sclk_adc_config;
	 
	 
	 assign tx = tx_B;
	 
	 assign host_mosi = mosi_adc_config;
	 
	 assign host_sclk = sclk_adc_config;
	 
	 // Definição dos estados (Verilog clássico)
    localparam GPIO_CONFIG = 3'b000;
	 localparam CPLD_RST_AD = 3'b001;
	 localparam TESTE_RAM = 3'b010;
	 localparam TESTE_SPI_AD = 3'b011;
	 localparam SEND_X01 = 3'b100;
	 localparam CONFIG_AD = 3'b101;
	 localparam RESET_AD = 3'b110;
	 localparam IDLE_AD = 3'b111;
	 
	 reg [2:0] current_initial_state;
	 
	  uart_tx_8 u_uart_tx_8(
	  
	  .clk(clk),
     .rst(rst_hardware),       
     .start(start_8_ctl),     
     .tx(tx_8B),        
     .busy(),      
     .done(done_8_ctl)       
	  
);

	driver_ADS8691 u_driver_ADS8691 (

    .clk(clk),
    .rst(reset_adc_config),       // reset síncrono
	 .driver_ncs(ncs_adc_config),
	 .driver_sclk(sclk_adc_config),
	 .driver_mosi(mosi_adc_config)	 
    	 
);

	 always @(posedge clk) begin
	 
	 
	 if (!rst_hardware) begin
        delay <= 24'b0;
		  start_8_ctl <= 1'b0;
		  reset_adc_config <= 1'b1;
		  //select <= 2'b00;
		  select0_1 <= 1'b0;
		  select1_1 <= 1'b0;
		  current_initial_state <= GPIO_CONFIG; 
    end
	 
	 else begin
	 
	 case (current_initial_state)
		
        GPIO_CONFIG:
			  
			   begin
			       
					 delay <= delay + 1;
					 rst <= 1'b0;
					 if (delay == 24'd10000000) begin
					     delay <= 24'b0;
						  rst <= 1'b1;
						  current_initial_state <= CPLD_RST_AD;
					 end
					 
					 else begin
					     current_initial_state <= GPIO_CONFIG;
					 end
					 
				end
				
		  CPLD_RST_AD:
			  
			   begin
			      
					 delay <= delay + 1;
					 if ((delay == 2100000) & (rst == 1'b1)) begin
					     delay <= 1'b0;
						  rst <= 1'b0;
						  current_initial_state <= CPLD_RST_AD;
					 end
					 else if ((delay == 200) & (rst == 1'b0)) begin
					     delay <= 1'b0;
						  rst <= 1'b1;
						  current_initial_state <= TESTE_RAM;
					 end
					 
			       			              
		      end
			
			TESTE_RAM:
			  
			   begin
			      
					 current_initial_state <= TESTE_SPI_AD;
			       
		      end
				
		 TESTE_SPI_AD:
			  
			  begin
			      
					current_initial_state <= SEND_X01;
			       		       
		     end
				
		 SEND_X01:
			  
			  begin
			      
			      start_8_ctl <= 1'b1;
					//select <= 2'b10;
					select0_1 <= 1'b0;
					select1_1 <= 1'b1;
					
					if (done_8_ctl == 1'b1) begin
					    start_8_ctl <= 1'b0;
						 convst <= ncs_adc_config;
						 //select <= 2'b00;
						 select0_1 <= 1'b0;
						 select1_1 <= 1'b0;
						 current_initial_state <= CONFIG_AD;
					end
					else begin
					    current_initial_state <= SEND_X01;
					end
			       		       
		     end
				
		CONFIG_AD:
			  
			 begin
			     reset_adc_config <= 1'b0;
				  if (ncs_adc_config == 1'b1) begin
						convst <= 1'b1;
				      current_initial_state <= RESET_AD;
				  end
				  else begin
				      current_initial_state <= CONFIG_AD;
				  end
				  
				  
		    end
		
		RESET_AD:
			  
			 begin
				  
			     delay <= delay + 1;
				  if (delay == 24'd1000) begin
					   delay <= 24'b0;
						convst <= 1'b0;
						current_initial_state <= IDLE_AD;
				  end
				  else begin
						current_initial_state <= RESET_AD;
				  end
				  
				  
		    end
		
		IDLE_AD:
			  
			 begin     
				  current_initial_state <= IDLE_AD;				  				  
		    end		
					  
	 endcase
	 
	 end
	           
		  
 end
	 
	 
endmodule
	 
	 
	 
       