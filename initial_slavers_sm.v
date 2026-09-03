module slaver_states (

    input  wire clk,
	 input  wire rst_hardware,
    output reg  rst,
	 output wire tx,
	 output wire convst_out,
	 output wire host_mosi_out,
	 output wire host_sclk_out,
	 output wire select0_0_out,
	 output wire select1_0_out,
	 output reg[1:0] host_mode,
	 output wire reset_sm_laver_out
	 
);    

    reg convst;
	 wire host_mosi;
	 wire host_sclk;
	 reg select0_0;
	 reg select1_0;
	 reg reset_sm_laver;

    assign convst_out = convst;
	 assign host_mosi_out = host_mosi;
	 assign host_sclk_out = host_sclk;
	 assign select0_0_out = select0_0;
	 assign select1_0_out = select1_0;
	 assign reset_sm_laver_out = reset_sm_laver;

	 reg [2:0] channel_config;	  
    reg [23:0]  delay;
	 reg start_8_ctl;
	 reg reset_uart;
	 
	 reg reset_adc_config;
	 reg [7:0] data_to_send;
	 wire ncs_adc_config;
	 wire done_8_ctl;
	 
	 
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
	 
	 //Definição dos estados (Verilog clássico)
    localparam MODE_CFG_FPGA = 2'b00;
	 localparam MODE_CFG = 2'b01;
	 localparam MODE_ACQ = 2'b10;
	 localparam MODE_RW = 2'b11;
	 
	  uart_tx_8 u_uart_tx_8(
	  
	  .clk(clk),
     .rst(reset_uart),       
     .start(start_8_ctl),
	  .data_in(data_to_send),
     .tx_out(tx),        
     .busy_out(),      
     .done_out(done_8_ctl)	  
	  
);


spi_adc u_spi_adc(
	 
    .clk(clk),
    .rst(reset_adc_config),       // reset síncrono
	 .sclk(host_sclk),
	 .ncs(ncs_adc_config),
	 .mosi(host_mosi)      // PINO DE OUTPUT DO MESTRE

);


	 always @(posedge clk) begin
	 
	 
	 if (!rst_hardware) begin
	     reset_uart <= 1'b1;
		  channel_config <= 3'd0;
        delay <= 24'd0;
		  start_8_ctl <= 1'b0;
		  reset_adc_config <= 1'b1;
		  select0_0 <= 1'b0;
		  select1_0 <= 1'b0;
		  data_to_send <= 8'h00;
		  current_initial_state <= GPIO_CONFIG;
		  host_mode <= MODE_CFG_FPGA;
		  reset_sm_laver <= 1'b1;
		 
    end
	 
	 else begin
	 
	 case (current_initial_state)
		
        GPIO_CONFIG:
			   begin
			       
					 delay <= delay + 1;
					 rst <= 1'b0;
					 if (delay == 24'd10000000) begin
						  
					     delay <= 24'd0;
						  rst <= 1'b1;
						  current_initial_state <= CPLD_RST_AD;
					 end
					 
					 else begin
					     current_initial_state <= GPIO_CONFIG;
					 end
					 
				end
				
		  CPLD_RST_AD:
			  
			   begin
			       host_mode <= MODE_CFG;
					 delay <= delay + 1;
					 if ((delay == 24'd2100000) & (rst == 1'b1)) begin
					     delay <= 24'd0;
						  rst <= 1'b0;
						  current_initial_state <= CPLD_RST_AD;
					 end
					 else if ((delay == 24'd200) & (rst == 1'b0)) begin
						  
					     delay <= 24'd0;
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
			  
					data_to_send <= 8'h01;
					start_8_ctl <= 1'b1;
					reset_uart <= 1'b0;
					select0_0 <= 1'b0;
					select1_0 <= 1'b1;
					current_initial_state <= SEND_X01;
			       		       
		     end
				
		 SEND_X01:
			  
			  begin
			
			      start_8_ctl <= 1'b0;
					convst <= 1'b1;
					if (done_8_ctl == 1'b1) begin
					
						 reset_uart <= 1'b1;
						 select0_0 <= 1'b0;
						 select1_0 <= 1'b0;
			
						 reset_adc_config <= 1'b0;
				       
					end
					
					 if (ncs_adc_config == 1'b0) begin
					     convst <= 1'b0;
						  channel_config <= channel_config + 3'd1;
						  current_initial_state <= CONFIG_AD;  
						  
					 end
				
			       		       
		     end
				
		CONFIG_AD:
			  
		begin
			     	  
		if (ncs_adc_config == 1'b1) begin
				      
			 current_initial_state <= RESET_AD; 	
				  		  
		end
		end
		
		RESET_AD:
			  
			 begin
				  convst <= 1'b1;
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
			     
			     reset_sm_laver <= 1'b0;
				  host_mode <= MODE_CFG_FPGA;
				  current_initial_state <= IDLE_AD;				  				  
		    end		
					  
	 endcase
	 
	 end
	           
		  
 end
	 
	 
endmodule
	 
	 
	 
       