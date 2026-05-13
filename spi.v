module spi_4_20 (

    input  wire        clk,
    input  wire        rst,       // reset síncrono
	 output reg         sclk,
	 output reg         ncs,
    input wire         miso,      // PINO DE INPUT DO MESTRE
	 output reg         mosi,       // PINO DE OUTPUT DO MESTRE
	 output reg         done_miso,
	 input [15:0]   config_reg,       
	 output reg [15:0]  data_reg       

);    
	 
	  
    reg [15:0] old_config_reg; // precisa contar até 9
	 reg [4:0]  bit_cnt;
	 reg [7:0]  div_sclk;
	 reg [4:0]  delay;
	 reg [15:0] shift_reg;
	 
	 reg        miso_enable;
	 
	 // Definição dos estados (Verilog clássico)
    localparam NO_MOSI_DATA = 3'b000;
	 localparam CHIP_SELECTED = 3'b001;
	 localparam DELAY_CSSC_MOSI = 3'b010;
	 localparam AWAIT_SCLK_FALL_MOSI = 3'b011;
	 localparam AWAIT_SCLK_RISE_MOSI = 3'b100;
	 localparam DELAY_SCCS_MOSI = 3'b101;
	 localparam IDLE_MOSI = 3'b110;
	 
	 reg [2:0] current_mosi_state;
	 
	 // Definição dos estados (Verilog clássico)
    localparam IDLE_MISO = 3'b000;
	 localparam AWAIT_MISO_DATA = 3'b001;
	 localparam MISO_DATA_READY = 3'b010;
	 localparam DELAY_CSSC_MIS0 = 3'b011;
	 localparam AWAIT_SCLK_FALL_MISO = 3'b100;
	 localparam AWAIT_SCLK_RISE_MISO = 3'b101;
	 localparam DELAY_SCCS_MIS0 = 3'b110;
	 
	 reg [2:0] current_miso_state;
	 
	 
	 
	 always @(posedge clk) begin
	 
	 
	 if (rst) begin
            sclk <= 1'b0;
            ncs <= 1'b1;
				mosi <= 1'b0;
				div_sclk <= 8'd0;
				delay <= 5'd0;
				bit_cnt <= 5'd15;
				done_miso <= 1'b0;
				
				
				current_mosi_state <= NO_MOSI_DATA;
				
				current_miso_state <= IDLE_MISO;
				
				miso_enable <= 1'b0; 
        end
	 
	 else begin
	 
	 case (current_mosi_state)
		
        NO_MOSI_DATA:
			  
			   begin
			       if (config_reg == 16'd0) begin
					     current_mosi_state <= NO_MOSI_DATA;
                end
					 else begin
                	  current_mosi_state <= CHIP_SELECTED;
						  ncs <= 1'b0;
						  
                end
					 			              
				end
				
		  CHIP_SELECTED:
			  
			   begin
			      
			       current_mosi_state <= DELAY_CSSC_MOSI;
                /*real design begin*/
					 shift_reg <= config_reg;
					  /*real design end*/
					  /*only for loopback begin*/
					 //shift_reg <= old_config_reg;
					  /*only for loopback end*/
					 old_config_reg <= config_reg;
			              
		      end
			
			DELAY_CSSC_MOSI:
			  
			   begin
			      
			       delay  <= delay + 5'd1;
					 //200 ns to satisfy delay between nCS falling and first SCLK rising
					 if (delay == 5'd20) begin
					     delay <= 5'd0;
						  current_mosi_state <= AWAIT_SCLK_FALL_MOSI;
						  mosi <= shift_reg[15];
						  sclk <= 1'b1;
					 end   					 
			       else begin
					     current_mosi_state <= DELAY_CSSC_MOSI;
						  
					 end   					       
		      end
				
		 AWAIT_SCLK_FALL_MOSI:
			  
			  begin
			      
					div_sclk  <= div_sclk + 8'd1;
					//await 1 us to low sclk based on fsclk = 500 kHz
					if (div_sclk == 8'd99) begin
					    div_sclk <= 8'd0;
						 sclk <= 1'b0;
						 shift_reg <= shift_reg << 1;
						 bit_cnt <= bit_cnt - 1;
						 if (bit_cnt == 5'd0) begin
						     current_mosi_state <= DELAY_SCCS_MOSI;
							  bit_cnt <= 5'd15;
							  mosi <= 1'b0;
						 end
						 else begin
						     current_mosi_state <= AWAIT_SCLK_RISE_MOSI;
						 end
						  					  
					end
					 
					else begin
					    current_mosi_state <= AWAIT_SCLK_FALL_MOSI;
					end
			       		       
		      end
				
		 AWAIT_SCLK_RISE_MOSI:
			  
			  begin
			      
					div_sclk  <= div_sclk + 8'd1;
					//await 1 us to low sclk based on fsclk = 500 kHz
					if (div_sclk == 8'd99) begin
					    sclk <= 1'b1;
						 div_sclk <= 8'd0;
						 mosi <= shift_reg[15];
						 current_mosi_state <= AWAIT_SCLK_FALL_MOSI;
					end
					else begin
					    current_mosi_state <= AWAIT_SCLK_RISE_MOSI;
					end
			       		       
		     end
				
		DELAY_SCCS_MOSI:
			  
			 begin
			      
			     delay  <= delay + 5'd1;
				  //200 ns to satisfy delay between SCLK falling and nCS rising 
				  if (delay == 5'd20) begin
					   delay <= 5'd0;
						ncs <= 1'b1;
						miso_enable <= 1'b1;
						current_mosi_state <= IDLE_MOSI;
						  
				  end
				  
			     else begin					 
					   
					   current_mosi_state <= DELAY_SCCS_MOSI;
						  
				  end   					       
		    end		
				
		IDLE_MOSI:
			  
			 begin
			      
			     if (config_reg == old_config_reg) begin
				      current_mosi_state <= IDLE_MOSI;
						 
				  end
				  else begin
					   current_mosi_state <= NO_MOSI_DATA;
				      		
				  end
					 
			       		       
		      end
				
	 
	  endcase 
	 
	 case (current_miso_state)
	 
	 IDLE_MISO:
	 begin
	 done_miso <= 1'b0;
	 if (miso_enable == 1'b0) begin
	     current_miso_state <= IDLE_MISO;
	 end
	 else begin
	     current_miso_state <= AWAIT_MISO_DATA;
	 end
	 
	 end
	 
	 AWAIT_MISO_DATA:
	 begin
	 
	 if (miso == 1'b1) begin
	     current_miso_state <= AWAIT_MISO_DATA;
	 end
	 else begin
	     current_miso_state <= MISO_DATA_READY;
	 end
	 
	 end
	 
	 MISO_DATA_READY:
	 begin	
	     ncs <= 1'b0;
		  current_miso_state <= DELAY_CSSC_MIS0;
	 
	 end
	 
	 DELAY_CSSC_MIS0:
	 begin
	     delay  <= delay + 5'd1;
		  //200 ns to satisfy delay between nCS falling and first SCLK rising
		  if (delay == 5'd20) begin
				delay <= 5'd0;
				current_miso_state <= AWAIT_SCLK_FALL_MISO;
				
				sclk <= 1'b1;
		  end   					 
		  else begin
		      current_miso_state <= DELAY_CSSC_MIS0;				  
		  end   			
	 
	 end
	 
	 AWAIT_SCLK_FALL_MISO:
			  
			  begin
			      
					div_sclk  <= div_sclk + 8'd1;
					//await 1 us to low sclk based on fsclk = 500 kHz
					if (div_sclk == 8'd99) begin
					    div_sclk <= 8'd0;
						 sclk <= 1'b0;
						 data_reg[bit_cnt] <= miso;
						 bit_cnt <= bit_cnt - 1;
						 if (bit_cnt == 5'd0) begin
						     current_miso_state <= DELAY_SCCS_MIS0;
							  bit_cnt <= 5'd15;
							  
						 end
						 else begin
						     current_miso_state <= AWAIT_SCLK_RISE_MISO;
						 end
						  					  
					end
					 
					else begin
					    current_miso_state <= AWAIT_SCLK_FALL_MISO;
					end
			       		       
		      end
				
		 AWAIT_SCLK_RISE_MISO:
			  
			  begin
			      
					div_sclk  <= div_sclk + 8'd1;
					//await 1 us to low sclk based on fsclk = 500 kHz
					if (div_sclk == 8'd99) begin
					    sclk <= 1'b1;
						 div_sclk <= 8'd0;
						 current_miso_state <= AWAIT_SCLK_FALL_MISO;
					end
					else begin
					    current_miso_state <= AWAIT_SCLK_RISE_MISO;
					end
			       		       
		     end

	  DELAY_SCCS_MIS0:
			  
			 begin
			      
			     delay  <= delay + 5'd1;
				  
				  //200 ns to satisfy delay between SCLK falling and nCS rising 
				  if (delay == 5'd20) begin
					   delay <= 5'd0;
						ncs <= 1'b1;
						done_miso <= 1'b1;
						current_miso_state <= IDLE_MISO;
						miso_enable <= 1'b0;
						  
				  end
				  
			     else begin					 
					   
					   current_miso_state <= DELAY_SCCS_MIS0;
						  
				  end   					       
		    end		
	 
	 
	 
	 endcase
	 
	 end
	   
	 
          
		  
 end
	 
	 
endmodule
	 
	 
	 
       