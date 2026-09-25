module slaver_states_main (

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

    output reg [1:0] host_mode,

    output wire led_dft_on_out,
    output wire led_tx_on_out,
	 output wire tx_8

);

    (* preserve, noprune *) reg reset_uart_rx;
    (* preserve *) reg txd_reg;


    (* preserve *) reg requested_data;
    assign txd_to_gpio46 = txd_reg;
    reg acquire_again;
    reg select0_1;
    reg select1_1;
    reg convst;
    reg in;
    reg dft_reg;
    reg tx_reg;
    wire host_sclk;
    wire host_mosi;

    assign led_dft_on_out = dft_reg;
    assign led_tx_on_out = tx_reg;
    assign requested_data_out = requested_data;
    assign acquire_again_out = acquire_again;
    assign select0_1_out = select0_1;
    assign select1_1_out = select1_1;
    assign convst_out = convst;
    assign host_sclk_out = host_sclk;
    assign host_mosi_out = host_mosi;


    //22 bit size register to insert delay thick 
    (* preserve *) reg [21:0] is_finished;


    //4 bit size register to count 4 bytes to be sent on 32 bits SPI writing
    reg [3:0] bytes_counter;
	 
	 //4 bit size register to count 4 bytes to be sent on 32 bits SPI writing
    reg [3:0] payload_bytes_counter;

    //32 bit size register to store 4 bytes returned through SPI
    reg [31:0] readed_data_32;

    //16 bit size register to count 7215 (samples) * 6 (channels for all samples) * 1 (word by sample)
    reg [15:0] readed_words;

    //Signal to send new byte through SPI
    reg command_new_byte;

    //New byte itsel to be sent through SPI
    reg [7:0] byte_to_send;

    //Reg of 8 bits to store size of payload
    reg [7:0] lenth_reg;

    //Reg of 8 bits to store type byte
    reg [7:0] type_reg;
    
    //Reg of 8 bits to store type byte
    reg [7:0] payload_reg[0:7];
	 
	 //Reg of 8 bits to store crc low
    reg [7:0] crc_low_reg;
	 
	 //Reg of 8 bits to store crc high
    reg [7:0] crc_high_reg;
	 
    //8 bit size register to store one byte returned through SPI
    wire [7:0] readed_data_8;

    //Signal that indicates when spi communication is over
    wire signal_spi_done;
    
	 //To restart crc16 after one frame received
	 reg crc_restart;
	 reg [7:0] data_in_crc;
	 reg crc_en_reg;
	 wire [15:0] crc_result;
	 wire crc_global_reset;
	 assign crc_global_reset = rst | crc_restart;
	 //Instance of crc16-CCITT False to calculate crc 16 bits data
    crc16 u_crc16(
	 
		  .data_in(data_in_crc),
        .crc_en(crc_en_reg),
        .crc_out(crc_result),
        .rst(crc_global_reset),
        .clk(clk)
		  
);
	 
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
        .rst(reset_uart_rx),           // reset
        .rx(rxd_from_gpio47),          // dado serie
        .busy_rx(),                    // está transmitindo
        .done_rx(done_rx_to_read_ed),  // pulso de fim
        .rx_reg(rx_uart_out)	 

    );
	 
	 reg start_8_ctl;
	 wire done_8_ctl;
	 
	 uart_tx_8 u_uart_tx_8(
	  
	     .clk(clk),
        .rst(rst),       
        .start(start_8_ctl),
	     .data_in(byte_to_send),
        .tx_out(tx_8),            
        .done_out(done_8_ctl)	  
	  
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
	 
	 wire id_valid;
	 wire [63:0] fpga_id;
	 //Instance to get id of MAX1008SCE144
	 altchip_id u_altchip_id
        (
        .clkin(clk),
        .chip_id(id_valid),
        .data_valid(fpga_id),
        .reset(rst)
		  );


    //Bytes of protocol
    localparam START_BYTE = 8'h01;//Start of frame byte
	 localparam END_BYTE = 8'h04;//End of frame byte
    localparam ECHO_BYTE = 8'h01;//Echo byte
    localparam GET_ID_BYTE = 8'h02;//Get ID byte
    localparam GET_CONFIG_BYTE = 8'h10;//Get config byte
    localparam SET_CONFIG_BYTE = 8'h20;//Set config byte
    localparam PROPAGATION_BYTE = 8'h30;//Propagation byte
    localparam PREPARE_50HZ_BYTE = 8'h31;//Prepare sync for 50 Hz signal byte
    localparam PREPARE_60HZ_BYTE = 8'h32;//Prepare sync for 60 Hz signal byte
    localparam MEASURE_BYTE = 8'h33;//Measure byte
    localparam GET_RESULTS_BYTE = 8'h40;//Get results byte
    localparam BYPASS_BYTE = 8'h50;//Bypass byte
    localparam ERROR_BYTE = 8'h7F;//Error byte	 

    //States definition for states machine of slaver IED
    localparam CHECK_SOH = 5'b00000;//UART await for SOH byte
    localparam CHECK_LENGTH = 5'b00001;//UART await for length of payload
    localparam CHECK_TYPE = 5'b00010;//UART await for TYPE byte
	 localparam READ_PAYLOAD = 5'b00011;//UART store payload byte by byte
	 localparam CHECK_END = 5'b00100;//UART await byte of end
    localparam READ_CRC_LOW = 5'b00101;//UART await sent CRC LOW BYTE
    localparam READ_CRC_HIGH = 5'b00110;//UART await sent CRC HIGH BYTE
	 localparam CHECK_INTEGRITY = 5'b00111;//Check integrity of frame
	 localparam DO_COMMAND = 5'b01000;//Do sent command
    localparam EN_W_1 = 5'b01001;//Reading current write key with writing enable bit
    localparam EN_W_2 = 5'b01010;//Send first byte on next clock
    localparam EN_W_3 = 5'b01011;//Writing write key with writing enable bit activated
    localparam PREPARE_CONVERSION = 5'b01100;//Prepare IED slaver to receive next pulse as conversion trigger
    localparam START_CONVERSION = 5'b01101;//Trigg AD conversion for 50 Hz or 60 Hz, as chosen previously in type_byte
    localparam AWAIT_END_CONVERSION = 5'b01110;//Await 35 ms to conversion completes
    localparam DIS_W_1 = 5'b01111;//Reading current write key with writing enable bit
    localparam DIS_W_2 = 5'b10000;//Send first byte on next clock
    localparam DIS_W_3 = 5'b10001;//Writing write key with writing enable bit desactivated
    localparam CALC_PHASORS = 5'b10010;//Requesting SRAM data of 86580 bytes
    localparam DELAY_SAMPLES = 5'b10011;//Requesting SRAM data of 86580 bytes
    localparam AWAIT_CORRENTE_TX = 5'b10100; //Request 58 bytes which is all data available (phasors, temp and 4-20mA)
    localparam AWAIT_HIGH = 5'b10101; 
    localparam AWAIT_LOW = 5'b10110; 
    (* preserve *) reg [4:0] current_state;

    //Modes definition to internal connection of switch module
    localparam MODE_CFG_FPGA = 2'b00;
    localparam MODE_CFG = 2'b01;
    localparam MODE_ACQ = 2'b10;
    localparam MODE_RW = 2'b11;

    always @(posedge clk) begin

	     in <= rxd_from_gpio47;
	 
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
				payload_bytes_counter <= 4'd0;
            reset_uart_rx <= 1'b1;
            host_mode <= MODE_CFG_FPGA;
            dft_reg <= 1'b1;
            tx_reg <= 1'b1;
            lenth_reg <= 8'h00;
				
				data_in_crc <= 8'h00;
	         crc_en_reg <= 1'b0;
				crc_restart  <= 1'b0;
				
				payload_reg[0] <= 8'h00;
				payload_reg[1] <= 8'h00;
				payload_reg[2] <= 8'h00;
				payload_reg[3] <= 8'h00;
				payload_reg[4] <= 8'h00;
				payload_reg[5] <= 8'h00;
				payload_reg[6] <= 8'h00;
				payload_reg[7] <= 8'h00;
				crc_low_reg <= 8'h00;
				crc_high_reg <= 8'h00;
				start_8_ctl <= 1'b0;
            byte_to_send <= 8'h00;

        end

        else begin

            //state machine
            case (current_state)			  

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

                end

                CHECK_SOH:

                begin
					     //Restart crc for new frame
						  crc_restart  <= 1'b0;
						  //Free uart rx for new frame
                    reset_uart_rx <= 1'b0;
						  //Uart tx not started, that is, it will started on demand
                    start_8_ctl <= 1'b0;
						  //Disable 4-20 ma + temp request, that is, it will started only once after request is done
                    acquire_again <= 1'b0;
                    if (ed_rx_done == 1'b1) begin

                        if (rx_uart_out == START_BYTE) begin
								
									 data_in_crc <= START_BYTE;
	                         crc_en_reg <= 1'b1;
                            current_state <= CHECK_LENGTH;
									 
                        end

                        else begin
                            current_state <= CHECK_SOH;
                        end

                    end

                    else begin

                        current_state <= CHECK_SOH;

                    end						

                end

                CHECK_LENGTH:

                begin


                    if (ed_rx_done == 1'b1) begin
						  
								crc_en_reg <= 1'b1;
								data_in_crc <= rx_uart_out;
								
                        lenth_reg <= rx_uart_out;
                        current_state <= CHECK_TYPE;

                        end
                    else begin
						  
							   crc_en_reg <= 1'b0;
                        current_state <= CHECK_LENGTH;

                    end						

                end 	

                CHECK_TYPE:

                begin

                    if (ed_rx_done == 1'b1) begin
						  
						      //FRAME OF ECHO
                        if (rx_uart_out == ECHO_BYTE) begin
										
									 crc_en_reg <= 1'b1;
								    data_in_crc <= ECHO_BYTE;
                            
                            type_reg <= ECHO_BYTE;
                            current_state <= READ_PAYLOAD;

                        end
								
								//FRAME TO GET ID
                        else if (rx_uart_out == GET_ID_BYTE) begin
										
									 crc_en_reg <= 1'b1;
								    data_in_crc <= GET_ID_BYTE;
                            
                            type_reg <= GET_ID_BYTE;
                            current_state <= READ_PAYLOAD;

                        end
								
								//FRAME TO GET CONFIG
                        else if (rx_uart_out == GET_CONFIG_BYTE) begin
										
									 crc_en_reg <= 1'b1;
								    data_in_crc <= GET_CONFIG_BYTE;
                            
                            type_reg <= GET_CONFIG_BYTE;
                            current_state <= READ_PAYLOAD;

                        end
								
								//FRAME TO SET CONFIG
                        else if (rx_uart_out == SET_CONFIG_BYTE) begin
										
									 crc_en_reg <= 1'b1;
								    data_in_crc <= SET_CONFIG_BYTE;
                            
                            type_reg <= SET_CONFIG_BYTE;
                            current_state <= READ_PAYLOAD;

                        end
								
                        //FRAME OF DELAY
                        else if (rx_uart_out == PROPAGATION_BYTE) begin
										
									 crc_en_reg <= 1'b1;
								    data_in_crc <= PROPAGATION_BYTE;
                            
                            type_reg <= PROPAGATION_BYTE;
                            current_state <= READ_PAYLOAD;

                        end

                        //FRAME OF SYNC 50
                        else if (rx_uart_out == PREPARE_50HZ_BYTE)  begin
                            
									 crc_en_reg <= 1'b1;
								    data_in_crc <= PREPARE_50HZ_BYTE;
									 
									 type_reg <= PREPARE_50HZ_BYTE;
									 current_state <= READ_PAYLOAD;

                        end
								
								//FRAME OF SYNC 60
                        else if (rx_uart_out == PREPARE_60HZ_BYTE)  begin
                            
									 crc_en_reg <= 1'b1;
								    data_in_crc <= PREPARE_60HZ_BYTE;
									 
									 type_reg <= PREPARE_60HZ_BYTE;
									 current_state <= READ_PAYLOAD;
									 
                        end
							    //FRAME OF MEASURE
                        else if (rx_uart_out == MEASURE_BYTE)  begin
                            
									 crc_en_reg <= 1'b1;
								    data_in_crc <= MEASURE_BYTE;
									 
									 type_reg <= MEASURE_BYTE;
									 current_state <= READ_PAYLOAD;
								
                        end
                        //FRAME OF DATA_REQUEST
                        else if (rx_uart_out == GET_RESULTS_BYTE)  begin
                            
									 crc_en_reg <= 1'b1;
								    data_in_crc <= GET_RESULTS_BYTE;
									 
									 type_reg <= GET_RESULTS_BYTE;
									 current_state <= READ_PAYLOAD;

                        end
								
								//FRAME OF BYPASS
                        else if (rx_uart_out == BYPASS_BYTE)  begin
                            
									 crc_en_reg <= 1'b1;
								    data_in_crc <= BYPASS_BYTE;
									 
									 type_reg <= BYPASS_BYTE;
									 current_state <= READ_PAYLOAD;

                        end
								
								//FRAME OF ERROR
                        else if (rx_uart_out == ERROR_BYTE)  begin
                            
									 crc_en_reg <= 1'b1;
								    data_in_crc <= ERROR_BYTE;
									 
									 type_reg <= ERROR_BYTE;
									 current_state <= READ_PAYLOAD;

                        end
								
                        //NO VALID FRAME
                        else  begin
								    crc_restart  <= 1'b1;
                            current_state <= CHECK_SOH;
                        end

                    end

                    else begin
						  
						      crc_en_reg <= 1'b0;
                        current_state <= CHECK_TYPE;
								
                    end						

                end
					 
					 READ_PAYLOAD:

                begin
					     
						  if (bytes_counter == lenth_reg) begin
						  
						      crc_en_reg <= 1'b0;
								payload_bytes_counter <= 4'd0;
						      current_state <= CHECK_END;
						  
						  end

                    else if (ed_rx_done == 1'b1) begin
						      	
								crc_en_reg <= 1'b1;
								data_in_crc <= rx_uart_out;
								
                        payload_reg[payload_bytes_counter] <= rx_uart_out;
								payload_bytes_counter <= payload_bytes_counter + 1;					

                    end
						  
						  else begin
						  
						      crc_en_reg <= 1'b0;
								
						  end
						  
					 end
				
                CHECK_END:

                begin

                    if (ed_rx_done == 1'b1) begin
						      	
								if (rx_uart_out == END_BYTE) begin
									 
									 crc_en_reg <= 1'b1;
								    data_in_crc <= END_BYTE;
                            current_state <= READ_CRC_LOW;

                        end					

                    end
						  
					 end
		
					READ_CRC_LOW:

               begin
					
                   crc_en_reg <= 1'b0;
                   if (ed_rx_done == 1'b1) begin
						  
							  crc_low_reg <= rx_uart_out;
                       current_state <= READ_CRC_HIGH;
 				
                   end
						  
					end
		
					READ_CRC_HIGH:

               begin

                   if (ed_rx_done == 1'b1) begin
						  
							  crc_low_reg <= rx_uart_out;
                       current_state <= CHECK_INTEGRITY;
 				
                   end
						  
					end
		
				 CHECK_INTEGRITY:

             begin

					 if (crc_result == {crc_high_reg, crc_low_reg}) begin
					 
						  current_state <= DO_COMMAND;
						  
					 end
					 else begin
					 
						  current_state <= CHECK_SOH;
						  
					 end
					 //Restart crc16 once that it won't be used again until next frame
					 crc_restart  <= 1'b1;
						  
				 end
		
				 DO_COMMAND:

             begin

					  case (type_reg)
					  
					     ECHO_BYTE: begin
						  
						      if ((select0_1 != 1'b1) && (select1_1 != 1'b1)) begin
								
								    select0_1 <= 1'b1;
									 select1_1 <= 1'b1;
									 
									 //Send byte of start through uart
                            start_8_ctl <= 1'b1;
									 byte_to_send <= START_BYTE;
									 byte_counter <= byte_counter + 1;
									 
								end
								else begin
								
								    start_8_ctl <= 1'b0;
									 
								end
								
								if (done_8_ctl == 1'b1)
								
									 if ((byte_to_send == START_BYTE) && (byte_counter == 4'd1))
									
									     //Send byte of length through uart
									     start_8_ctl <= 1'b1;
									     byte_to_send <= lenth_reg;
										  byte_counter <= byte_counter + 1;
									 
									 end
								
								    else if ((byte_to_send == lenth_reg) && (byte_counter == 4'd2))
									 
									     //Send type byte through uart
									     start_8_ctl <= 1'b1;
									     byte_to_send <= type_reg;
										  byte_counter <= 4'd0;
									 
									 end
								
								    else if (payload_bytes_counter < lenth_reg)
									 
										  //Send bytes of payload through uart
									     start_8_ctl <= 1'b1;
									     byte_to_send <= payload_reg[payload_bytes_counter];
										  payload_bytes_counter <= payload_bytes_counter + 1;
									 
									 end
									 
									 else if (payload_bytes_counter == lenth_reg)
									 
									     //Send byte of end through uart
									     start_8_ctl <= 1'b1;
									     byte_to_send <= END_BYTE;
										  payload_bytes_counter <= payload_bytes_counter + 1;
										  
									 end
									 
									 else if (payload_bytes_counter == (lenth_reg + 8'h01))
									 
										  //Send byte low of crc
									     start_8_ctl <= 1'b1;
									     byte_to_send <= crc_low_byte;
										  payload_bytes_counter <= payload_bytes_counter + 1;
										  
									 end
									 
									 else if (payload_bytes_counter == (lenth_reg + 8'h02))
									 
									     //Send byte high of crc
									     start_8_ctl <= 1'b1;
									     byte_to_send <= crc_high_byte;
										  payload_bytes_counter <= 4'd0;
										  select0_1 <= 1'b0;
									     select1_1 <= 1'b0;
										  current_state <= CHECK_SOH;
										  
									 end
									 
								end
								
                    end
						  
						  GET_ID_BYTE: begin
						      
                        if ((select0_1 != 1'b1) && (select1_1 != 1'b1)) begin
								
								    select0_1 <= 1'b1;
									 select1_1 <= 1'b1;
									 
									 //Send byte of start through uart
                            start_8_ctl <= 1'b1;
									 byte_to_send <= START_BYTE;
									 byte_counter <= byte_counter + 1;
									 
								end
								else begin
								
								    start_8_ctl <= 1'b0;
									 
								end
								
								if (done_8_ctl == 1'b1)
								
									 if ((byte_to_send == START_BYTE) && (byte_counter == 4'd1))
									
									     //Send byte of length through uart
									     start_8_ctl <= 1'b1;
									     byte_to_send <= 8'h08;
										  byte_counter <= byte_counter + 1;
									 
									 end
								
								    else if ((byte_to_send == lenth_reg) && (byte_counter == 4'd2))
									 
									     //Send type byte through uart
									     start_8_ctl <= 1'b1;
									     byte_to_send <= type_reg;
										  byte_counter <= 4'd0;
										  if(id_valid) begin
										      payload_reg[0] <= fpga_id[7:0];
												payload_reg[1] <= fpga_id[15:8];
												payload_reg[2] <= fpga_id[23:16];
												payload_reg[3] <= fpga_id[31:24];
												payload_reg[4] <= fpga_id[39:32];
												payload_reg[5] <= fpga_id[47:40];
												payload_reg[6] <= fpga_id[55:48];
												payload_reg[7] <= fpga_id[63:56];
										  end
									 
									 end
								
								    else if (payload_bytes_counter < 8'h08)
									 
										  //Send bytes of payload through uart
									     case (byte_counter)
										      4'd0: fpga_id_byte <= fpga_id[7:0];
												      payload_bytes_counter <= payload_bytes_counter + 1;
												4'd1: fpga_id_byte <= fpga_id[15:8];
												      payload_bytes_counter <= payload_bytes_counter + 1;
												4'd2: fpga_id_byte <= fpga_id[23:16];
												      payload_bytes_counter <= payload_bytes_counter + 1;
												4'd3: fpga_id_byte <= fpga_id[31:24];
												      payload_bytes_counter <= payload_bytes_counter + 1;
												4'd4: fpga_id_byte <= fpga_id[39:32];
												      payload_bytes_counter <= payload_bytes_counter + 1;
												4'd5: fpga_id_byte <= fpga_id[47:40];
												      payload_bytes_counter <= payload_bytes_counter + 1;
												4'd6: fpga_id_byte <= fpga_id[55:48];
												      payload_bytes_counter <= payload_bytes_counter + 1;
												4'd7: fpga_id_byte <= fpga_id[63:56];
												      payload_bytes_counter <= payload_bytes_counter + 1;
										  endcase
										  
										  payload_bytes_counter <= payload_bytes_counter + 1;
									 
									 end
									 
									 else if (payload_bytes_counter == lenth_reg)
									 
									     //Send byte of end through uart
									     start_8_ctl <= 1'b1;
									     byte_to_send <= END_BYTE;
										  payload_bytes_counter <= payload_bytes_counter + 1;
										  
									 end
									 
									 else if (payload_bytes_counter == (lenth_reg + 8'h01))
									 
										  //Send byte low of crc
									     start_8_ctl <= 1'b1;
									     byte_to_send <= crc_low_byte;
										  payload_bytes_counter <= payload_bytes_counter + 1;
										  
									 end
									 
									 else if (payload_bytes_counter == (lenth_reg + 8'h02))
									 
									     //Send byte high of crc
									     start_8_ctl <= 1'b1;
									     byte_to_send <= crc_high_byte;
										  payload_bytes_counter <= 4'd0;
										  select0_1 <= 1'b0;
									     select1_1 <= 1'b0;
										  current_state <= CHECK_SOH;
										  
									 end
									 
								end
								
                    end
					  
						  GET_CONFIG_BYTE: begin
						      
                        
								
                    end
						  
						  SET_CONFIG_BYTE: begin
						      
                        
								
                    end

						  PROPAGATION_BYTE: begin
						  
						      reset_uart_rx <= 1'b1;
                        select0_1 <= 1'b1;
								select1_1 <= 1'b0;
								current_state <= AWAIT_HIGH;
								
                    end

                    PREPARE_50HZ_BYTE: begin
						  
						      select0_1 <= 1'b0;
                        select1_1 <= 1'b0;
                        current_state <= EN_W_1;
                        frequency <= 1'b1;
								
                        //byte 1 to be sent
                        command_new_byte <= 1'b1;
                        byte_to_send <= 8'h00;
                        bytes_counter <= bytes_counter + 1;
                        
                    end

                    PREPARE_60HZ_BYTE: begin
						  
                        current_state <= EN_W_1;
                        select0_1 <= 1'b0;
                        select1_1 <= 1'b0;
                        frequency <= 1'b0;
								
                        //byte 1 to be sent
                        command_new_byte <= 1'b1;
                        byte_to_send <= 8'h00;
                        bytes_counter <= bytes_counter + 1;
                        
                    end
						  
						  MEASURE_BYTE: begin
						      
								
                    end
						  
						  GET_RESULTS_BYTE: begin
						      
                        requested_data <= 1'b1;
                        tx_reg <= 1'b0;
                        current_state <= AWAIT_CORRENTE_TX;
								
                    end
						  
						  BYPASS_BYTE: begin
						      
                       
								
                    end
						  
						  ERROR_BYTE: begin
						      
                       
								
                    end

                   
                endcase

						  
				 end
		
		
                EN_W_1:

                begin

                    command_new_byte <= 1'b0;

                    if (signal_spi_done == 1'b1) begin

                        bytes_counter <= bytes_counter + 1;									

                        if (bytes_counter == 4'd1) begin

                            readed_data_32 <= {readed_data_8, 24'h000000};
                            //byte 2 to be sent
                            command_new_byte <= 1'b1;
                            byte_to_send <= 8'h00;

                        end

                        else if (bytes_counter == 4'd2) begin

                            readed_data_32 <= {readed_data_32[31:24], readed_data_8, 16'h0000};
                            //byte 3 to be sent
                            command_new_byte <= 1'b1;
                            byte_to_send <= 8'h00;

                        end
                        else if (bytes_counter == 4'd3) begin

                            readed_data_32 <= {readed_data_32[31:16], readed_data_8, 8'h00};
                            //byte 4 to be sent
                            command_new_byte <= 1'b1;
                            byte_to_send <= 8'h00;

                        end
                        else if (bytes_counter == 4'd4) begin

                            readed_data_32 <= {readed_data_32[31:8], readed_data_8};
                            bytes_counter <= 4'd0;											  

                        end
                    end

                    if (bytes_counter == 4'd0) begin

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

                        if (bytes_counter == 4'd1) begin

                            //byte 2 to be sent
                            command_new_byte <= 1'b1;
                            byte_to_send <= readed_data_32[23:16];

                        end

                        else if (bytes_counter == 4'd2) begin

                            //byte 3 to be sent
                            command_new_byte <= 1'b1;
                            byte_to_send <= readed_data_32[15:8];

                        end
                        else if (bytes_counter == 4'd3) begin

                            //byte 4 to be sent
                            command_new_byte <= 1'b1;
                            byte_to_send <= readed_data_32[7:0];

                        end
                        else if (bytes_counter == 4'd4) begin

                            bytes_counter <= 4'd0;

                        end

                    end

                    if (bytes_counter == 4'd0) begin

                        convst <= 1'b0;

                        is_finished <= is_finished + 1;

                        if (is_finished == 22'd2000000) begin
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
                        host_mode <= MODE_ACQ;
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

                        byte_to_send <= 8'h00;

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

                        if (bytes_counter == 4'd1) begin

                            readed_data_32 <= {readed_data_8, 24'h000000};
                            //byte 2 to be sent
                            command_new_byte <= 1'b1;
                            byte_to_send <= 8'h00;

                        end

                        else if (bytes_counter == 4'd2) begin

                            readed_data_32 <= {readed_data_32[31:24], readed_data_8, 16'h0000};
                            //byte 3 to be sent
                            command_new_byte <= 1'b1;
                            byte_to_send <= 8'h00;

                        end
                        else if (bytes_counter == 4'd3) begin

                            readed_data_32 <= {readed_data_32[31:16], readed_data_8, 8'h00};
                            //byte 4 to be sent
                            command_new_byte <= 1'b1;
                            byte_to_send <= 8'h00;

                        end
                        else if (bytes_counter == 4'd4) begin

                            readed_data_32 <= {readed_data_32[31:8], readed_data_8};
                            bytes_counter <= 4'd0;

                        end


                    end

                    if (bytes_counter == 4'd0) begin

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

                        if (bytes_counter == 4'd1) begin

                            //byte 2 to be sent
                            command_new_byte <= 1'b1;
                            byte_to_send <= readed_data_32[23:16];

                        end

                        else if (bytes_counter == 4'd2) begin

                            //byte 3 to be sent
                            command_new_byte <= 1'b1;
                            byte_to_send <= readed_data_32[15:8];

                        end
                        else if (bytes_counter == 4'd3) begin

                            //byte 4 to be sent
                            command_new_byte <= 1'b1;
                            byte_to_send <= readed_data_32[7:0];
                        end
                        else if (bytes_counter == 4'd4) begin

                            bytes_counter <= 4'd0;

                            host_mode <= MODE_RW;

                            current_state <= CALC_PHASORS;

                        end

                    end

                end

                CALC_PHASORS:

                begin
                    dft_reg <= 1'b0;
                    //Command to read first byte
                    if (bytes_counter == 4'd0) begin

                        bytes_counter <= 4'd1;
                        command_new_byte <= 1'b1;
                        byte_to_send <= 8'h00;     									

                    end

                    else begin
                        //After one cycle of 100 MHz, command get down
                        command_new_byte <= 1'b0;

                    end

                    if ((signal_spi_done == 1'b1) & (bytes_counter == 4'd1)) begin

                        //First byte is readed
                        //Then command to read second byte
                        bytes_counter <= 4'd2;
                        command_new_byte <= 1'b1;
                        byte_to_send <= 8'h00;

                    end

                    else if ((signal_spi_done == 1'b1) & (bytes_counter == 4'd2)) begin

                        //Second byte readed then more one word is readed
                        readed_words <= readed_words + 1;
                        //Commands occur only until last word
                        if (readed_words < 16'd43289) begin
                            current_state <= DELAY_SAMPLES;  
                        end

                        else begin
                            dft_reg <= 1'b1;
                            readed_words <= 16'd0;
                            bytes_counter <= 4'd0;
                            host_mode <= MODE_CFG_FPGA;

                            current_state <= CHECK_SOH;
                        end

                    end							 							 					    

                end

                DELAY_SAMPLES:
                begin
                    is_finished  <= is_finished + 1;
                    if (is_finished == 22'd50) begin
                        //Command to read another first byte of next word
                        bytes_counter <= 4'd1;
                        command_new_byte <= 1'b1;
                        byte_to_send <= 8'h00;
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
                        tx_reg <= 1'b1;
								//After request data is done, enable other 4-20 + temp measure is requested
                        acquire_again <= 1'b1;
                        current_state <= CHECK_SOH;

                    end
                end

            endcase			  

        end

    end

endmodule