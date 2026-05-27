module sm_corrente_await (

    input  wire  clk,
    input  wire  rst,       // reset síncrono
	 input wire rxd_from_gpio47,
	 input wire done_tx,
	 input wire host_miso,
	 output reg led_conv_60,
	 output reg led_conv_50,
	 output reg txd_to_gpio46,
	 output reg requested_data,
	 output reg acquire_again,
	 output reg select0_0,
	 output reg select1_0,
	 output reg convst,
	 output wire host_sclk,
	 output wire host_mosi,
	 
	 output wire [8:0] sampling_period_output,
	 
	 output reg [1:0] host_mode
    	 
);

    // Sinal interno para conectar o done_rx de rx_serial_8 a entrada
    //current_read_pulse de edge_detector
    wire done_rx_to_read_ed;	 
	 
	 wire [7:0] rx_uart_out;
	 
	 reg [21:0] is_finished;
	 
	 reg delayF;
	 
	 reg [8:0] sampling_period;
	 
	 reg command_new_byte;
	 
	 reg [7:0] byte_to_send;
	 
	 wire signal_nedge_sclk;
	 
	 reg [4:0] sclk_edges_counter;
	 
	 reg [3:0] bytes_counter;
	 
	 reg [7:0] readed_data_8;
	 
	 reg [31:0] readed_data_32;
	 
	 
	 assign sampling_period_output = sampling_period;
	 
	  nedge_detector u_nedge_detector(
		.current_read_pulse(signal_sclk),
		.clk(clk),
		.falling_edge(signal_nedge_sclk),
		.reset(rst)
);
	 
	 fpga_rw_8 u_fpga_rw_8 (

    .clk(clk),
	 .again(command_new_byte),
    .rst(rst),       // reset síncrono
	 .config_reg(byte_to_send),
	 .data_reg(readed_data_8),
	 .miso(host_miso),
	 .sclk(host_sclk),
	 .mosi(host_mosi)       // PINO DE OUTPUT DO MESTRE
	 
);
 
	 
	 rx_serial_8 u_rx_serial_8(
    .clk(clk),
    .rst(rst),                          // reset
    .rx(rxd_from_gpio47),               // dado serie
    .busy_rx(),                         // está transmitindo
    .done_rx(done_rx_to_read_ed),       // pulso de fim
	 .rx_reg(rx_uart_out)

);


// Sinal interno para conectar à saída do edge detector
    wire ed_rx_done;

// Instância do módulo edge_detector
    edge_detector u_edge_detector (
        .current_read_pulse(done_rx_to_read_ed),   // entrada
        .clk(clk),                        // clock
        .reset(rst),                    // reset
        .rising_edge(ed_rx_done)  // saída
    );

	 
	 // Sinal interno para conectar à saída do edge detector
    wire ed_new_pulse;

// Instância do módulo edge_detector
    edge_detector new_pulse_edge_detector (
        .current_read_pulse(rxd_from_gpio47),   // entrada
        .clk(clk),                        // clock
        .reset(rst),                    // reset
        .rising_edge(ed_new_pulse)  // saída
    );
  
    //Definição dos estados (Verilog clássico)
    localparam CHECK_SOH = 4'b0000;
	 localparam CHECK_TYPE = 4'b0001;
	 localparam EN_W_1 = 4'b0010;
	 localparam EN_W_2 = 4'b0011;
	 localparam PREPARE_CONVERSION = 4'b0100;
	 localparam START_CONVERSION = 4'b0101;
	 localparam AWAIT_END_CONVERSION = 4'b0110;
	 localparam DIS_W_1 = 4'b0111;
	 localparam DIS_W_2 = 4'b1000;
	 localparam CALC_PHASORS = 4'b1001;
	 localparam AWAIT_CORRENTE_TX = 4'b1010; 

	 reg [3:0] current_state;
	 
	 //Definição dos estados (Verilog clássico)
    localparam MODE_CFG_FPGA = 2'b00;
	 localparam MODE_CFG = 2'b01;
	 localparam MODE_ACQ = 2'b10;
	 localparam MODE_RW = 2'b11;
	 
	always @(posedge clk) begin
							 							 	    
		 if(rst) begin
		     current_state <= CHECK_SOH;
			  txd_to_gpio46 <= 1'b0;
			  is_finished  <= 22'd0;
			  delayF <= 1'd0;
			  sampling_period <= 9'd0;
			  led_conv_60 <= 1'b0;
			  led_conv_50 <= 1'b0;
			  requested_data <= 1'b0;
			  acquire_again <= 1'b0;
			  convst <= 1'b0;
			  command_new_byte <= 1'b0;
			  sclk_edges_counter <= 5'd0;

		 end
		 
		 else begin
		 
		     if ((ed_new_pulse == 1'b1) & (delayF == 1'b1)) begin
			      txd_to_gpio46 = 1'b1;
					
					select0_0 <= 1'b0;
					select1_0 <= 1'b0;
				   delayF = 1'b0;	
		     end
		     //state machine
		     case (current_state)			  
			          			  
			      CHECK_SOH:
			  
			          begin
							  acquire_again <= 1'b0;
			              if (ed_rx_done == 1'b1) begin
				               
						         if (rx_uart_out == 8'h01) begin
																			 
						             current_state <= CHECK_TYPE;
							 						
			                  end
									
									else begin
									    current_state <= CHECK_SOH;
									end
									
							  end
							      
						     else begin
							      current_state <= CHECK_SOH;
							  end						
			              
						 end 

			      CHECK_TYPE:
			  
			          begin
			      
			              if (ed_rx_done == 1'b1) begin
				               //FRAME OF DELAY
						         if (rx_uart_out == 8'h13) begin
										 delayF <= 1'b1;
										 
										 select0_0 <= 1'b1;
										 select1_0 <= 1'b0;
						             current_state <= CHECK_SOH;
						             txd_to_gpio46 = 1'b0;							 						
			                  end
									
									//FRAME OF SYNC 60
									else if (rx_uart_out == 8'h0C)  begin
									    current_state <= EN_W_1;
										 sampling_period <= 9'd231;
										 //byte 1 to be sent
										 command_new_byte <= 1'b1;
										 byte_to_send <= 1'h00;
										 bytes_counter <= bytes_counter + 1;
										 
									end
									//FRAME OF SYNC 50
									else if (rx_uart_out == 8'h2A)  begin
									    current_state <= EN_W_1;
										 sampling_period <= 9'd277;
										 //byte 1 to be sent
										 command_new_byte <= 1'b1;
										 byte_to_send <= 1'h00;
										 bytes_counter <= bytes_counter + 1;
									end
									//FRAME OF DATA_REQUEST
									else if (rx_uart_out == 8'h1E)  begin
									    current_state <= AWAIT_CORRENTE_TX;
										 requested_data <= 1'b1;
									end
									//NO VALID FRAME
									else  begin
									    current_state <= CHECK_TYPE;
									end
																		
							  end
							      
						     else begin
							      current_state <= CHECK_TYPE;
							  end						
			              
						 end
						 
						 EN_W_1:
			  
			          begin
						 
						     if (signal_nedge_sclk == 1'b1) begin
							      
									sclk_edges_counter <= sclk_edges_counter + 1;									
									command_new_byte <= 1'b0;
									
									if (sclk_edges_counter == 5'd16) begin
									
										 bytes_counter <= bytes_counter + 1;
							          sclk_edges_counter <= 5'd0;
										
										 
										 if (bytes_counter == 3'd1) begin
										     
											  readed_data_32 <= {readed_data_8, 24'h000000};
											  //byte 2 to be sent
											  command_new_byte <= 1'b1;
											  byte_to_send <= 1'h00;
									
							          end
										 
										 else if (bytes_counter == 3'd2) begin
										 
										     readed_data_32 <= {readed_data_32[31:24], readed_data_8, 16'h0000};
											  //byte 3 to be sent
											  command_new_byte <= 1'b1;
											  byte_to_send <= 1'h00;
									
							          end
										 else if (bytes_counter == 3'd3) begin
										     
										     readed_data_32 <= {readed_data_32[31:16], readed_data_8, 8'h00};
											  //byte 4 to be sent
											  command_new_byte <= 1'b1;
											  byte_to_send <= 1'h00;
									
							          end
										 else if (bytes_counter == 3'd4) begin
										     
										     readed_data_32 <= {readed_data_32[31:8], readed_data_8};
											  bytes_counter <= 3'd0;
											  
									
							          end
									
							      end
							  end
							  
							  if (bytes_counter == 3'd0) begin
									
									//32 bit returned data completed 
									readed_data_32 <= readed_data_32 | 32'hAC000001;
																		
									//byte 1 to be sent
									command_new_byte <= 1'b1;
									byte_to_send <= readed_data_32[31:24];
									bytes_counter <= bytes_counter + 1;
									
									host_mode <= MODE_CFG_FPGA;
											  
									current_state <= EN_W_2;
									
							  end
			          							  
						 end
						 
						 EN_W_2:
						 
						 begin
						 						 
						 if (signal_nedge_sclk == 1'b1) begin
							      
							  sclk_edges_counter <= sclk_edges_counter + 1;									
							  command_new_byte <= 1'b0;
									
							  if (sclk_edges_counter == 5'd16) begin
									
									bytes_counter <= bytes_counter + 1;
							      sclk_edges_counter <= 5'd0;
																				 
									if (bytes_counter == 3'd1) begin
											  
										 //byte 2 to be sent
										 command_new_byte <= 1'b1;
										 byte_to_send <= readed_data_32[23:16];
									
							      end
										 
									else if (bytes_counter == 3'd2) begin
										 
										 //byte 3 to be sent
										 command_new_byte <= 1'b1;
										 byte_to_send <= readed_data_32[15:8];
									
							      end
									else if (bytes_counter == 3'd3) begin
										     
										 //byte 4 to be sent
										 command_new_byte <= 1'b1;
										 byte_to_send <= readed_data_32[7:0];
									
							      end
									else if (bytes_counter == 3'd4) begin
										     										     
										 bytes_counter <= 3'd0;
									
							      end
									
							      end
							  end
							  
							  if (bytes_counter == 3'd0) begin
										     
									convst <= 1'b0;
									
									host_mode <= MODE_ACQ;
									
									is_finished <= is_finished + 1;
									
								   if (is_finished == 22'd1000) begin
										 is_finished <= 22'd0;
									    current_state <= PREPARE_CONVERSION;
									end
								   									
						     end
						 						 
						 end
						 
						 PREPARE_CONVERSION:
			  
			          begin
						 
			              if(is_finished < 10000) begin
							      is_finished  <= is_finished + 22'd1;    
							  end
							  else begin
							      is_finished  <= 10000;
							  end
							  
							  if ((is_finished == 10000) & (rxd_from_gpio47 == 1'b0)) begin
									current_state <= START_CONVERSION;
								   is_finished <= 22'd0;
							  end
							  else begin
							      current_state <= PREPARE_CONVERSION;
							  end
							  
						 end
					
						START_CONVERSION:
			  
			          begin
			              
							  if (ed_new_pulse == 1'b1) begin
							      if (sampling_period == 9'd231) begin
									    led_conv_60 = 1'b1;
										 convst = 1'b1;
									end
									
									else if (sampling_period == 9'd277) begin
									    led_conv_50 = 1'b1;
										 convst = 1'b1;
									end
									
							      current_state <= AWAIT_END_CONVERSION;
	
							  end
							  
							  else begin
							      current_state <= START_CONVERSION;
							  end
							  
						 end
						 
						 AWAIT_END_CONVERSION:
			  
			          begin
			              
							  if(is_finished < 22'd3500000) begin
							      is_finished  <= is_finished + 1;    
							  end
							  else begin
							      is_finished  <= 22'd3500000;
							  end
						     
							  if (is_finished == 22'd3500000) begin
									current_state <= DIS_W_1;
									
									byte_to_send <= 1'h00;
									
									bytes_counter <= bytes_counter + 1;
									
									command_new_byte <= 1'b1;
									
									host_mode <= MODE_CFG_FPGA;
																											
								   is_finished <= 22'd0;
							  end
							  else begin
									current_state <= AWAIT_END_CONVERSION;
							  end	  
							  
						 end
						 
						 DIS_W_1:
			  
			          begin
			              
						 if (signal_nedge_sclk == 1'b1) begin
							      
								sclk_edges_counter <= sclk_edges_counter + 1;									
								command_new_byte <= 1'b0;
								
								if (sclk_edges_counter == 5'd16) begin
								
									 bytes_counter <= bytes_counter + 1;
									 sclk_edges_counter <= 5'd0;
									
									 
									 if (bytes_counter == 3'd1) begin
										  
										  readed_data_32 <= {readed_data_8, 24'h000000};
										  //byte 2 to be sent
										  command_new_byte <= 1'b1;
										  byte_to_send <= 1'h00;
								
									 end
									 
									 else if (bytes_counter == 3'd2) begin
									 
										  readed_data_32 <= {readed_data_32[31:24], readed_data_8, 16'h0000};
										  //byte 3 to be sent
										  command_new_byte <= 1'b1;
										  byte_to_send <= 1'h00;
								
									 end
									 else if (bytes_counter == 3'd3) begin
										  
										  readed_data_32 <= {readed_data_32[31:16], readed_data_8, 8'h00};
										  //byte 4 to be sent
										  command_new_byte <= 1'b1;
										  byte_to_send <= 1'h00;
								
									 end
									 else if (bytes_counter == 3'd4) begin
										  
										  readed_data_32 <= {readed_data_32[31:8], readed_data_8};
										  bytes_counter <= 3'd0;
										  
								
									 end
								
								end
						 end
							  
						 if (bytes_counter == 3'd0) begin
								
							  //32 bit returned data completed 
							  readed_data_32 <= (readed_data_32 | 32'hAC000000) & (32'hFFFFFFFE);
																	
							  //byte 1 to be sent
							  command_new_byte <= 1'b1;
							  byte_to_send <= readed_data_32[31:24];
							  bytes_counter <= bytes_counter + 1;
								
							  host_mode <= MODE_CFG_FPGA;
										  
							  current_state <= DIS_W_2;
								
						 end
					    
							  
						 end
						 
						 DIS_W_2:
			  
			          begin
			              
						 if (signal_nedge_sclk == 1'b1) begin
							      
							  sclk_edges_counter <= sclk_edges_counter + 1;									
							  command_new_byte <= 1'b0;
									
							  if (sclk_edges_counter == 5'd16) begin
									
									bytes_counter <= bytes_counter + 1;
							      sclk_edges_counter <= 5'd0;
																				 
									if (bytes_counter == 3'd1) begin
											  
										 //byte 2 to be sent
										 command_new_byte <= 1'b1;
										 byte_to_send <= readed_data_32[23:16];
									
							      end
										 
									else if (bytes_counter == 3'd2) begin
										 
										 //byte 3 to be sent
										 command_new_byte <= 1'b1;
										 byte_to_send <= readed_data_32[15:8];
									
							      end
									else if (bytes_counter == 3'd3) begin
										     
										 //byte 4 to be sent
										 command_new_byte <= 1'b1;
										 byte_to_send <= readed_data_32[7:0];
							      end
									else if (bytes_counter == 3'd4) begin
										     										     
										 bytes_counter <= 3'd0;
										 
										 current_state <= CALC_PHASORS;
									
							      end
									
							      end
							  end						 
						     
						 end
							  
					    CALC_PHASORS:
						 
						 begin
						     
						     host_mode <= MODE_RW;
							  
							  
							  
						 end
						 
						 
				       AWAIT_CORRENTE_TX:
						 begin
						     if (done_tx == 1'b0) begin
							      current_state <= AWAIT_CORRENTE_TX;
							  end
							  else begin
							      requested_data <= 1'b0;
									acquire_again <= 1'b1;
									current_state <= CHECK_SOH;
							  end
						 end
		
			  endcase			  
		 
		 end
	
	end
	
endmodule