module sm_corrente_await (

    input  wire  clk,
    input  wire  rst,       // reset síncrono
	 input wire rxd_from_gpio47,
	 input wire done_tx,
	 output reg led_conv_60,
	 output reg led_conv_50,
	 output reg txd_to_gpio46,
	 output reg requested_data
    	 
);

    // Sinal interno para conectar o done_rx de rx_serial_8 a entrada
    //current_read_pulse de edge_detector
    wire done_rx_to_read_ed;	 
	 
	 wire [7:0] rx_uart_out;
	 
	 reg [21:0] is_finished;
	 
	 reg delayF;
	 
	 reg [8:0] sampling_period;
	 
	 
	 
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
    localparam CHECK_SOH = 3'b000;
	 localparam CHECK_TYPE = 3'b001;
	 localparam PREPARE_CONVERSION = 3'b010;
	 localparam START_CONVERSION = 3'b011;
	 localparam AWAIT_END_CONVERSION = 3'b100;
	 localparam AWAIT_CORRENTE_TX = 3'b101;

	 reg [2:0] current_state;
	 
	always @(posedge clk) begin
							 							 	    
		 if(rst) begin
		     current_state <= CHECK_SOH;
			  txd_to_gpio46 <= 1'b0;
			  is_finished  <= 22'd0;
			  delayF <= 1'd1;
			  sampling_period <= 9'd0;
			  led_conv_60 <= 1'b0;
			  led_conv_50 <= 1'b0;
			  requested_data <= 1'b0;

		 end
		 
		 else begin
		 
		     if ((ed_new_pulse == 1'b1) & (delayF == 1'b1)) begin
			      txd_to_gpio46 = 1'b1;
				   delayF = 1'b0;	
		     end
		     //state machine
		     case (current_state)			  
			          			  
			      CHECK_SOH:
			  
			          begin
			      
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
						             current_state <= CHECK_SOH;
						             txd_to_gpio46 = 1'b0;							 						
			                  end
									
									//FRAME OF SYNC 60
									else if (rx_uart_out == 8'h0C)  begin
									    current_state <= PREPARE_CONVERSION;
										 sampling_period <= 9'd231;
									end
									//FRAME OF SYNC 50
									else if (rx_uart_out == 8'h2A)  begin
									    current_state <= PREPARE_CONVERSION;
										 sampling_period <= 9'd277;
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
									end
									
									else if (sampling_period == 9'd277) begin
									    led_conv_50 = 1'b1;
									end
									
							      current_state <= AWAIT_END_CONVERSION;
	
							  end
							  
							  else begin
							      current_state <= START_CONVERSION;
							  end
							  
						 end
						 
						 AWAIT_END_CONVERSION:
			  
			          begin
			              
							  if(is_finished < 3500000) begin
							      is_finished  <= is_finished + 22'd1;    
							  end
							  else begin
							      is_finished  <= 3500000;
							  end
						     
							  if (is_finished == 3500000) begin
									current_state <= CHECK_SOH;
								   is_finished <= 22'd0;
							  end
							  else begin
									current_state <= AWAIT_END_CONVERSION;
							  end	  
							  
						 end

				       AWAIT_CORRENTE_TX:
						 begin
						     if (done_tx == 1'b0) begin
							      current_state <= AWAIT_CORRENTE_TX;
							  end
							  else begin
							      requested_data <= 1'b0;
									current_state <= CHECK_SOH;
							  end
						 end
		
			  endcase			  
		 
		 end
	
	end
	
endmodule