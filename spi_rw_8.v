module fpga_rw_8 (

    input  wire        clk,
	 input  wire        again,
    input  wire        rst,       // reset síncrono
	 input  wire [7:0]  config_reg,
	 output reg  [7:0]  data_reg,
	 input wire 		  miso,
	 output reg         sclk,
	 output reg         mosi,       // PINO DE OUTPUT DO MESTRE
	 output reg         spi_done
	 
);    
	 	 
	 reg [3:0]  bit_cnt;
	 reg [7:0]  div_sclk;
	 	 
	 // Definição dos estados (Verilog clássico)
    localparam NO_DATA = 3'b00;
	 localparam AWAIT_SCLK_FALL = 3'b01;
	 localparam AWAIT_SCLK_RISE = 3'b10;
	 
	 
	 reg [1:0] current_spi_state;
	 
	 
	 always @(posedge clk) begin
	 
	 
	 if (rst) begin
	 
            sclk <= 1'b0;
				mosi <= 1'b0;
				div_sclk <= 8'd0;
				bit_cnt <= 4'd7;
				spi_done <= 1'b0;
				current_spi_state <= NO_DATA;
				
    end
	 
	 else begin
	 
	 case (current_spi_state)
		
        NO_DATA:
			  
			   begin
				
			       if (again == 1'd0) begin
					 
						  mosi <= config_reg[bit_cnt];
						  data_reg[bit_cnt] <= miso;	
					     current_spi_state <= NO_DATA;
						  if (bit_cnt == 4'd0) begin
						  
						      spi_done <= 1'b1;
								bit_cnt <= 4'd7;
								
						  end
						  else begin
						  
						      spi_done <= 1'b0;
								
						  end
						  
                end
					 
					 else begin	
					 
                	  current_spi_state <= AWAIT_SCLK_RISE;
						  
                end
					 			              
				end
						
				
		 AWAIT_SCLK_FALL:
			  
			  begin
			      
					div_sclk  <= div_sclk + 8'd1;
					//Await 1 us to low sclk based on fsclk = 500 kHz
					if (div_sclk == 8'd49) begin
					    div_sclk <= 8'd0;
						 sclk <= 1'b0;				 
						 
						 
						 if (bit_cnt == 4'd0) begin
							 
						     current_spi_state <= NO_DATA;
							  
						 end
						 else begin
						     bit_cnt <= bit_cnt - 1;
						     current_spi_state <= AWAIT_SCLK_RISE;
						 end
						  					  
					end
					 
					else begin
					    current_spi_state <= AWAIT_SCLK_FALL;
					end
			       		       
		      end
				
				
		 AWAIT_SCLK_RISE:
			  
			  begin
			      
					div_sclk  <= div_sclk + 8'd1;
					mosi <= config_reg[bit_cnt];
					data_reg[bit_cnt] <= miso;
					//await 1 us to low sclk based on fsclk = 500 kHz
					if (div_sclk == 8'd49) begin
					    sclk <= 1'b1;
						 div_sclk <= 8'd0;
						 current_spi_state <= AWAIT_SCLK_FALL;
					end
					else begin
					    current_spi_state <= AWAIT_SCLK_RISE;
					end
			       		       
		     end
		
	  endcase 
	 	 	 
	 end
	   	          		  
 end
	 
	 
endmodule
	 
	 
	 
       