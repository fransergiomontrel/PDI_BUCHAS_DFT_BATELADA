module sm_corrente_await (

    input  wire  clk,
    input  wire  rst,       // reset síncrono
	 input wire rxd_from_gpio47,
	 input wire done_tx,
	 input wire host_miso,
	 output wire txd_to_gpio46,
	 output wire requested_data_out,
	 output wire acquire_again_out,
	 output wire select0_1_out,
	 output wire select1_1_out,
	 output wire convst_out,
	 output wire host_sclk_out,
	 output wire host_mosi_out,
	 
	 output reg frequency,
	 
	 output reg [1:0] host_mode
	 
    	 
);
    
	 (* preserve, noprune *) reg reset_uart_rx;
	 (* preserve *) reg txd_reg;
	 
	 
    reg requested_data;
	 reg acquire_again;
	 reg select0_1;
	 reg select1_1;
	 reg convst;
	 wire host_sclk;
	 reg host_mosi_sclk;
	 reg in;
	 
	 
	 
	 assign txd_to_gpio46 = txd_reg;
	 assign requested_data_out = requested_data;
	 assign acquire_again_out = acquire_again;
	 assign select0_1_out = select0_1;
	 assign select1_1_out = select1_1;
	 assign convst_out = convst;
	 assign host_sclk_out = host_sclk;
	 assign host_mosi_out = host_mosi_sclk;
	 
	  
	 //22 bit size register to insert delay thick 
	 (* preserve *) reg [21:0] is_finished;
	 
	 
	 //4 bit size register to count 4 bytes to be sent on 32 bits SPI writing
	 reg [3:0] bytes_counter;
	 
	 //32 bit size register to store 4 bytes returned through SPI
	 reg [31:0] readed_data_32;
	 
	 //16 bit size register to count 7215 (samples) * 6 (channels for all samples) * 1 (word by sample)
	 reg [15:0] readed_words;
	 
	 //Signal to send new byte through SPI
	 reg command_new_byte;
	 
	 //New byte itsel to be sent through SPI
	 reg [7:0] byte_to_send;
	 
	 //8 bit size register to store one byte returned through SPI
	 wire [7:0] readed_data_8;
	 
	 //Signal that indicates when spi communication is over
	 wire signal_spi_done;
	 
	 //Instance of SPI to write and read one byte
	 fpga_rw_8 u_fpga_rw_8 (

    .clk(clk),
	 .again(command_new_byte),
    .rst(rst),       // reset síncrono
	 .config_reg(byte_to_send),
	 .data_reg(readed_data_8),
	 .miso(host_miso),
	 .sclk(host_sclk),
	 .mosi(host_mosi),
	 .spi_done(signal_spi_done)
	 
);

	 //Signal to notice that UART receptor ever received its byte 
    wire done_rx_to_read_ed;
	 //1 byte size register to store one received byte
	 wire [7:0] rx_uart_out;
	 
	 //Instance of UART receptor
	 rx_serial_8 u_rx_serial_8(
	 
    .clk(clk),
    .rst(reset_uart_rx),                          // reset
    .rx(rxd_from_gpio47),               // dado serie
    .busy_rx(),                         // está transmitindo
    .done_rx(done_rx_to_read_ed),       // pulso de fim
	 .rx_reg(rx_uart_out)	 
	 
);

    //Signal which outputs rising edge of UART rx done
    wire ed_rx_done;

   //Instance of rising edge detector for UART rx done
    edge_detector u_edge_detector (
        .current_read_pulse(done_rx_to_read_ed),   // entrada
        .clk(clk),                        // clock
        .reset(rst),                    // reset
        .rising_edge(ed_rx_done)  // saída
    );

	 
	 //Signal which outputs rising edge of arriving pulse on optical port
    wire ed_new_pulse;

    //Instance of rising edge detector for arriving pulse on optical port
    edge_detector new_pulse_edge_detector (
        .current_read_pulse(rxd_from_gpio47),  
        .clk(clk),                        
        .reset(rst),                    
        .rising_edge(ed_new_pulse)  
    );
  
    //States definition for states machine of slaver IED
    localparam CHECK_SOH = 5'b00000;//UART await for SOH byte
	 localparam CHECK_TYPE = 5'b00001;//UART await for TYPE byte
	 localparam EN_W_1 = 5'b00010;//Reading current write key with writing enable bit
	 localparam EN_W_2 = 5'b00011;//Send first byte on next clock
	 localparam EN_W_3 = 5'b00100;//Writing write key with writing enable bit activated
	 localparam PREPARE_CONVERSION = 5'b00101;//Prepare IED slaver to receive next pulse as conversion trigger
	 localparam START_CONVERSION = 5'b00110;//Trigg AD conversion for 50 Hz or 60 Hz, as chosen previously in type_byte
	 localparam AWAIT_END_CONVERSION = 5'b00111;//Await 35 ms to conversion completes
	 localparam DIS_W_1 = 5'b01000;//Reading current write key with writing enable bit
	 localparam DIS_W_2 = 5'b01001;//Send first byte on next clock
	 localparam DIS_W_3 = 5'b01010;//Writing write key with writing enable bit desactivated
	 localparam CALC_PHASORS = 5'b01011;//Requesting SRAM data of 86580 bytes
	 localparam DELAY_SAMPLES = 5'b01100;//Requesting SRAM data of 86580 bytes
	 localparam AWAIT_CORRENTE_TX = 5'b01101; //Request 58 bytes which is all data available (phasors, temp and 4-20mA)
    localparam AWAIT_LAST_BYTE = 5'b01110;
	 localparam AWAIT_HIGH = 5'b01111; 
	 localparam AWAIT_LOW = 5'b10000; 
	 (* preserve *) reg [4:0] current_state;
	 
	 //Modes definition to internal connection of switch module
    localparam MODE_CFG_FPGA = 2'b00;
	 localparam MODE_CFG = 2'b01;
	 localparam MODE_ACQ = 2'b10;
	 localparam MODE_RW = 2'b11;
	 
	always @(posedge clk) begin
							 							 	    
		 if(rst) begin
		     current_state <= CHECK_SOH;
			  txd_reg <= 1'b1;
			  is_finished  <= 22'd0;
			  frequency <= 1'b0;
			  select0_1 <= 1'b0;
			  select1_1 <= 1'b0;
			  requested_data <= 1'b0;
			  acquire_again <= 1'b0;
			  convst <= 1'b0;
			  command_new_byte <= 1'b0;
			  readed_words <= 16'd0;
			  bytes_counter <= 4'd0;
			  reset_uart_rx <= 1'b1;
			  in <= 1'b0;
			  
			  host_mode <= MODE_CFG_FPGA;

		 end
		 
		 else begin
			  in <= rxd_from_gpio47;
			  
		     //state machine
		     case (current_state)			  
	
					AWAIT_LAST_BYTE:
					
					begin
						
						if (ed_rx_done == 1'b1) begin
				           //
						     if (rx_uart_out == 8'h80) begin
										 
						         bytes_counter <= bytes_counter + 1;
									if (bytes_counter == 4'd1) begin
										  reset_uart_rx <= 1'b1;
									     bytes_counter <= 4'd0;
									     reset_uart_rx <= 1'b1;
									     current_state <= AWAIT_HIGH;
										  is_finished <= is_finished + 22'd1;
									end
										 									 
			              end
						
				      end
						end
					
					AWAIT_HIGH:
					
					begin
						
						is_finished <= is_finished + 22'd1;
						if (is_finished == 22'd2367) begin
									is_finished <= 22'd0;
									txd_reg <= 1'b0;
									current_state <= AWAIT_LOW;
						end
						
				   end
					
					AWAIT_LOW:
					
					begin
						
						if (in == 1'b1) begin
						    txd_reg <= 1'b1;
							 current_state <= CHECK_SOH;
					   end	
						//is_finished <= is_finished + 22'd1;
						//if (is_finished == 22'd2150) begin
							// is_finished <= 22'd0;
							// txd_reg <= 1'b1;
							 
							 
							 //current_state <= CHECK_SOH;
						//end
						
				   end
						 
			      CHECK_SOH:
			    
			          begin
						     reset_uart_rx <= 1'b0;
						     is_finished <= 22'd0;
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
										 
										 
										 select0_1 <= 1'b1;
										 select1_1 <= 1'b0;
										 
						             current_state <= AWAIT_LAST_BYTE;
						             
										 									 
			                  end
									
									//FRAME OF SYNC 60
									else if (rx_uart_out == 8'h0C)  begin
									    current_state <= EN_W_1;
										 select0_1 <= 1'b0;
										 select1_1 <= 1'b0;
										 frequency <= 1'b0;
										 //byte 1 to be sent
										 command_new_byte <= 1'b1;
										 byte_to_send <= 1'h00;
										 bytes_counter <= bytes_counter + 1;
										 
									end
									//FRAME OF SYNC 50
									else if (rx_uart_out == 8'h0D)  begin
									    select0_1 <= 1'b0;
										 select1_1 <= 1'b0;
									    current_state <= EN_W_1;
										 frequency <= 1'b1;
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
						 
							  command_new_byte <= 1'b0;
							  
						     if (signal_spi_done == 1'b1) begin
							      																		
									bytes_counter <= bytes_counter + 1;									
										 
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
							  
							 if (bytes_counter == 3'd0) begin
									
								  //32 bit returned data completed 
								  readed_data_32 <= readed_data_32 | 32'hAC000001;
																		
									
								  host_mode <= MODE_CFG_FPGA;
											  
								  current_state <= EN_W_2;
									
							  end
			          							  
						 end
						 
						 EN_W_2:
						 begin
						 
						     //byte 1 to be sent
							  command_new_byte <= 1'b1;
							  byte_to_send <= readed_data_32[31:24];
							  bytes_counter <= bytes_counter + 1;
							  current_state <= EN_W_3;
						 
						 end
						 
						 EN_W_3:
						 
						 begin
						 
						 command_new_byte <= 1'b0;
						 if (signal_spi_done == 1'b1) begin							      															  
									
							 bytes_counter <= bytes_counter + 1;
																				 
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
							  
						 if ((is_finished == 10000) & (in == 1'b0)) begin
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
						 
						 if (frequency == 1'b0) begin
							  convst <= 1'b1;
							  
						 end				
						 else if (frequency == 1'b1) begin

							  convst <= 1'b1;
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
			          command_new_byte <= 1'b0;   
						 if (signal_spi_done == 1'b1) begin
							      																	
							  bytes_counter <= bytes_counter + 1;
									 
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
							  
						 if (bytes_counter == 3'd0) begin
								
							  //32 bit returned data completed 
							  readed_data_32 <= (readed_data_32 | 32'hAC000000) & (32'hFFFFFFFE);
								
							  host_mode <= MODE_CFG_FPGA;
										  
							  current_state <= DIS_W_2;
								
						 end
					    
							  
						 end
						 
						 DIS_W_2:
			  
			          begin
						     //byte 1 to be sent
							  command_new_byte <= 1'b1;
							  byte_to_send <= readed_data_32[31:24];
							  bytes_counter <= bytes_counter + 1;
						     current_state <= DIS_W_3;
						 end
						 
						 DIS_W_3:
			  
			          begin
						 
						 command_new_byte <= 1'b0;
			              
						 if (signal_spi_done == 1'b1) begin	  
									
							  bytes_counter <= bytes_counter + 1;
																				 
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
										 
									host_mode <= MODE_RW;
									
									current_state <= CALC_PHASORS;
									
							  end
									
						end
							  					 			     
				end
							  
					    CALC_PHASORS:
						 
						 begin
							 //Command to read first byte
						     if (bytes_counter == 3'd0) begin
								
									bytes_counter <= 3'd1;
									command_new_byte <= 1'b1;
									byte_to_send <= 1'h00;     									
									
							  end
							  
							 else begin
								  //After one cycle of 100 MHz, command get down
								  command_new_byte <= 1'b0;
									
							 end
								
							 if ((signal_spi_done == 1'b1) & (bytes_counter == 3'd1)) begin
							  
								  //First byte is readed
								  //Then command to read second byte
								  bytes_counter <= 3'd2;
								  command_new_byte <= 1'b1;
								  byte_to_send <= 1'h00;
											  
							end

							else if ((signal_spi_done == 1'b1) & (bytes_counter == 3'd2)) begin
							 
								 //Second byte readed then more one word is readed
								 readed_words <= readed_words + 1;
								 //Commands occur only until last word
								 if (readed_words < 16'd43289) begin
									  current_state <= DELAY_SAMPLES;  
								 end
								 
								 else begin
									  readed_words <= 16'd0;
									  bytes_counter <= 3'd0;
								     host_mode <= MODE_CFG_FPGA;
									  
							        current_state <= CHECK_SOH;
								 end
								 								
							end							 							 					    
							  							  
					    end
						 
						 DELAY_SAMPLES:
						 begin
						     is_finished  <= is_finished + 1;
							  if (is_finished == 22'd200) begin
							      //Command to read another first byte of next word
								   bytes_counter <= 3'd1;
								   command_new_byte <= 1'b1;
								   byte_to_send <= 1'h00;
							      is_finished  <= 22'd0;
									current_state <= CALC_PHASORS;
							  end
						 end
						 						 
				       AWAIT_CORRENTE_TX:
						 
						 begin
						 
						     if (done_tx == 1'b0) begin
							  
									requested_data <= 1'b0;
							      current_state <= AWAIT_CORRENTE_TX;
									
							  end
							  else begin
							      
									acquire_again <= 1'b1;
									current_state <= CHECK_SOH;
									
							  end
						 end
		
			  endcase			  
		 
		 end
	
	end
	
endmodule