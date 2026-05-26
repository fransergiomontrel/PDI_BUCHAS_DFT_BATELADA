module sm_corrente_await (

    input  wire  clk,
    input  wire  rst,       // reset síncrono
	 input wire rxd_from_gpio47,
	 input wire done_tx,
	 output reg led_conv_60,
	 output reg led_conv_50,
	 output reg txd_to_gpio46,
	 output reg requested_data,
	 output reg acquire_again,
	 output reg select0_0,
	 output reg select1_0,
	 output reg convst,
	 output reg[1:0] host_mode,
	 output wire sclk,
	 output wire mosi
    	 
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
	 
	 wire signal_sclk;
	 
	 wire signal_nedge_sclk;
	 
	 reg [4:0] sclk_edges_counter;
	 
	 reg [3:0] bytes_counter;
	 
	 reg [7:0] readed_data_8;
	 
	 reg [31:0] readed_data_32;
	 
	 
	 assign sclk = signal_sclk;
	 
	 module nedge_detector(
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
	 .sclk(signal_sclk),
	 .mosi(mosi)       // PINO DE OUTPUT DO MESTRE
	 
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
  
    // Definição dos estados (Verilog clássico)
    localparam CHECK_SOH = 4'b0000;
	 localparam CHECK_TYPE = 4'b0001;
	 localparam RW_1 = 4'b0010;
	 localparam RW_2 = 4'b0011;
	 localparam PREPARE_CONVERSION = 4'b0100;
	 localparam START_CONVERSION = 4'b0101;
	 localparam AWAIT_END_CONVERSION = 4'b0110;
	 localparam AWAIT_CORRENTE_TX = 4'b0111;
	 

	 reg [3:0] current_state;
	 
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
					//select <= 2'b00;
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
										 //select <= 2'b01;
										 select0_0 <= 1'b1;
										 select1_0 <= 1'b0;
						             current_state <= CHECK_SOH;
						             txd_to_gpio46 = 1'b0;							 						
			                  end
									
									//FRAME OF SYNC 60
									else if (rx_uart_out == 8'h0C)  begin
									    current_state <= RW_1;
										 sampling_period <= 9'd231;
										 //byte 1
										 command_new_byte <= 1'b1;
										 byte_to_send <= 1'h00;
										 bytes_counter <= bytes_counter + 1;
										 
									end
									//FRAME OF SYNC 50
									else if (rx_uart_out == 8'h2A)  begin
									    current_state <= RW_1;
										 sampling_period <= 9'd277;
										 //byte 1
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
						 
						 RW_1:
			  
			          begin
						 
						     if (signal_nedge_sclk == 1'b1) begin
							      
									sclk_edges_counter <= sclk_edges_counter + 1;									
									command_new_byte <= 1'b0;
									
									if (sclk_edges_counter == 5'd15) begin
									
										 bytes_counter <= bytes_counter + 1;
							          sclk_edges_counter <= 5'd0;
										 command_new_byte <= 1'b1;
										 byte_to_send <= 1'h00;
										
										 
										 if (bytes_counter == 3'd1) begin
										     
											  readed_data_32 <= {readed_data_8, 24'h000000};
									
							          end
										 
										 else if (bytes_counter == 3'd2) begin
										 
										     readed_data_32 <= {readed_data_32[31:24], readed_data_8, 16'h0000};
									
							          end
										 else if (bytes_counter == 3'd3) begin
										     
										     readed_data_32 <= {readed_data_32[31:16], readed_data_8, 8'h00};
									
							          end
									
							      end
							  end
			          
							  
						 end
						 
						 RW_2:
						 begin
						 
						 end
						 
						 PREPARE_CONVERSION_2:
			  
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
									current_state <= DISABLE_WRITE;
									//host_mode 0 activated
									host_mode <= 2'b00;
								   is_finished <= 22'd0;
							  end
							  else begin
									current_state <= AWAIT_END_CONVERSION;
							  end	  
							  
						 end
						 
						 DISABLE_WRITE:
						 begin
						 
						    
		  
						 
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