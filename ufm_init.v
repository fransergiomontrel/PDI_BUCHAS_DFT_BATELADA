module ufm_start(
input clk,
input rst,
//(* preserve, noprune *) output reg [31:0] debug_data,
output reg debug_start,
output reg debug_test
);

(* preserve, noprune *) reg [31:0] debug_data_stp;
//(* preserve, noprune *) reg [31:0] debug_data_stp1;
(* preserve, noprune *) reg [12:0] ufm_addr;
//(* preserve, noprune *) reg [12:0] accepted_addr;
(* preserve, noprune *) reg ufm_read_reg;
wire [31:0] ufm_readdata;
wire ufm_waitrequest;
wire ufm_readdatavalid;

ufm_read u_ufm_read (
    .clock                   (clk),
    .reset_n                 (~rst),

    .avmm_data_addr          (ufm_addr),
    .avmm_data_read          (ufm_read_reg),
    .avmm_data_readdata      (ufm_readdata),
    .avmm_data_waitrequest   (ufm_waitrequest),
    .avmm_data_readdatavalid (ufm_readdatavalid),
    .avmm_data_burstcount    (4'd1)
);

localparam START = 3'd0;
localparam S_IDLE = 3'd1;
localparam S_REQ = 3'd2;
localparam S_WAIT = 3'd3;
//localparam S_WAIT1 = 3'd4;
localparam S_DONE = 3'd4;

(* preserve, noprune *) reg[2:0] state;
reg[6:0] count_start;

always @(posedge clk) begin

    if (rst) begin
		 state <= START;
	    ufm_addr <= 13'h0000;
		 ufm_read_reg <= 1'b0;
		 //debug_data <= 32'd0;
	    debug_test <= 1'b0;
		 debug_start <= 1'b0;
		 debug_data_stp <= 32'd0;
		 //debug_data_stp1 <= 32'd0;
		 count_start <= 7'd0;
		 //accepted_addr <= 13'h0000;
	 end
	 
	 else begin
	 case (state)
	 
		  START: begin
				debug_start <= 1'b1;
				ufm_read_reg <= 1'b0;
				if (count_start == 7'd50) begin
					 count_start <= 7'd0;
				    state <= S_IDLE;
			   end
				else begin
					 count_start <= count_start + 1'b1;
			   end
				
		  end
		  
	     S_IDLE: begin
				ufm_read_reg <= 1'b1;   
				state <= S_REQ;
		  end
		  
		  S_REQ: begin
				if(!ufm_waitrequest) begin
				    ufm_read_reg <= 1'b0;
					 state <= S_WAIT;
				end
		  end
		  
		  S_WAIT: begin
				if(ufm_readdatavalid) begin
					 debug_test <= 1'b1;
				    //debug_data <= ufm_readdata;
					 debug_data_stp <= ufm_readdata;
					 state <= S_DONE;
				end
		  end
		  
		  
		  S_DONE: begin   
				state <= S_DONE;
		  end
		  
	endcase
	end
	
end

endmodule
