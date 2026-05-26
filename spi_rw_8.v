module fpga_rw_8 (

    input  wire        clk,
	 input  wire        again,
    input  wire        rst,       // reset síncrono
	 input  [7:0]       config_reg,
	 output  [7:0]      data_reg,
	 input wire 		  miso,
	 output reg         sclk,
	 output reg         mosi       // PINO DE OUTPUT DO MESTRE
	 
);    
	 	 
	 reg [3:0]  bit_cnt;
	 reg [7:0]  div_sclk;
	 reg [1:0]  delay;
	 reg [7:0] shift_reg;
	 	 
	 // Definição dos estados (Verilog clássico)
    localparam NO_MOSI_DATA = 3'b000;
	 localparam TSU_CSCK_MOSI = 3'b001;
	 localparam AWAIT_SCLK_FALL_MOSI = 3'b010;
	 localparam AWAIT_SCLK_RISE_MOSI = 3'b011;
	 localparam NOP = 3'b100;
	 localparam AWAIT_SCLK_FALL_MISO = 3'b101;
	 localparam AWAIT_SCLK_RISE_MISO = 3'b110;
	 
	 
	 reg [2:0] current_spi_state;
	 
	 
	 always @(posedge clk) begin
	 
	 
	 if (rst) begin
	 
            sclk <= 1'b0;
				mosi <= 1'b0;
				div_sclk <= 8'd0;
				delay <= 2'd0;
				bit_cnt <= 4'd7;
				
				current_spi_state <= NO_MOSI_DATA;
				
        end
	 
	 else begin
	 
	 case (current_spi_state)
		
        NO_MOSI_DATA:
			  
			   begin
			       if (again == 1'd0) begin
					     current_spi_state <= NO_MOSI_DATA;
                end
					 
					 else begin					 
                	  current_spi_state <= TSU_CSCK_MOSI;
						  shift_reg <= config_reg;					  
                end
					 			              
				end
						
			TSU_CSCK_MOSI:
			  
			   begin
			      
			       delay  <= delay + 2'd1;
					 //20 ns to satisfy delay between nCS falling and first SCLK rising
					 if (delay == 2'd1) begin
					     delay <= 2'd0;
						  current_spi_state <= AWAIT_SCLK_FALL_MOSI;
						  mosi <= shift_reg[7];
						  sclk <= 1'b1;
					 end   					 
			       else begin
					 
					     current_spi_state <= TSU_CSCK_MOSI;
						  
					 end   					       
		      end
				
		 AWAIT_SCLK_FALL_MOSI:
			  
			  begin
			      
					div_sclk  <= div_sclk + 8'd1;
					//Await 1 us to low sclk based on fsclk = 500 kHz
					if (div_sclk == 8'd49) begin
					    div_sclk <= 8'd0;
						 sclk <= 1'b0;
						 shift_reg <= shift_reg << 1;
						 bit_cnt <= bit_cnt - 1;
						 if (bit_cnt == 4'd0) begin
						     current_spi_state <= NOP;
							  bit_cnt <= 4'd7;
							  mosi <= 1'b0;
							  
						 end
						 else begin
						     current_spi_state <= AWAIT_SCLK_RISE_MOSI;
						 end
						  					  
					end
					 
					else begin
					    current_spi_state <= AWAIT_SCLK_FALL_MOSI;
					end
			       		       
		      end
				
				
		 AWAIT_SCLK_RISE_MOSI:
			  
			  begin
			      
					div_sclk  <= div_sclk + 8'd1;
					//await 1 us to low sclk based on fsclk = 500 kHz
					if (div_sclk == 8'd49) begin
					    sclk <= 1'b1;
						 div_sclk <= 8'd0;
						 mosi <= shift_reg[7];
						 current_spi_state <= AWAIT_SCLK_FALL_MOSI;
					end
					else begin
					    current_spi_state <= AWAIT_SCLK_RISE_MOSI;
					end
			       		       
		     end
				
		NOP:
		     begin
					current_spi_state <= AWAIT_SCLK_FALL_MISO;
			      sclk <= 1'b1;
			  end
		
		AWAIT_SCLK_FALL_MISO:
			  
			  begin
			      
					div_sclk  <= div_sclk + 8'd1;
					//await 1 us to low sclk based on fsclk = 500 kHz
					if (div_sclk == 8'd49) begin
					    div_sclk <= 8'd0;
						 sclk <= 1'b0;
						 bit_cnt <= bit_cnt - 1;
						 data_reg[bit_cnt] <= miso;
						 
						 if (bit_cnt == 4'd0) begin
						     current_spi_state <= NO_MOSI_DATA;
							  bit_cnt <= 4'd7;
						 end
						 else begin
						     current_spi_state <= AWAIT_SCLK_RISE_MISO;
						 end
						  					  
					end
					 
					else begin
					    current_spi_state <= AWAIT_SCLK_FALL_MISO;
					end
			       		       
		      end
				
		 AWAIT_SCLK_RISE_MISO:
			  
			  begin
			      
					div_sclk  <= div_sclk + 8'd1;
					//await 1 us to low sclk based on fsclk = 500 kHz
					if (div_sclk == 8'd49) begin
					    sclk <= 1'b1;
						 div_sclk <= 8'd0;
						 current_spi_state <= AWAIT_SCLK_FALL_MISO;
					end
					else begin
					    current_spi_state <= AWAIT_SCLK_RISE_MISO;
					end
			       		       
		     end
			 
		
	  endcase 
	 	 	 
	 end
	   	          		  
 end
	 
	 
endmodule
	 
	 
	 
       