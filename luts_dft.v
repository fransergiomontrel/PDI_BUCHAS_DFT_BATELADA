module luts(

    input clk,
    input rst,
    input [12:0] addr,
    output  [15:0] sin,
    output [15:0] cos,
	 output wire debug_luts

);
//localparam [12:0] data_addr = 13'h0008;

(* preserve, noprune *) reg [15:0] sin_reg;
(* preserve, noprune *) reg [15:0] cos_reg;

assign sin = sin_reg;
assign cos = cos_reg;

assign debug_luts = fetch_seen;
reg ufm_read_reg;
wire [31:0] ufm_readdata;
wire ufm_waitrequest;
wire ufm_readdatavalid;

ufm_read u_ufm_read (

    .clock                   (clk),
    .reset_n                 (~rst),

    .avmm_data_addr          (prev_ufm_addr),
    .avmm_data_read          (ufm_read_reg),
    .avmm_data_readdata      (ufm_readdata),
    .avmm_data_waitrequest   (ufm_waitrequest),
    .avmm_data_readdatavalid (ufm_readdatavalid),
    .avmm_data_burstcount    (4'd1)
	 
);

localparam S_DELAY_FETCH = 3'd0;
localparam S_FETCH = 3'd1;
localparam S_REQ = 3'd2;
localparam S_WAIT = 3'd3;
localparam S_DONE = 3'd4;

reg[2:0] state;


reg [12:0] prev_ufm_addr;

reg fetch_seen;

always @(posedge clk) begin

    if (rst) begin
	 
        state <= S_DELAY_FETCH;
        ufm_read_reg <= 1'b0;
        sin_reg <= 16'd0;
		  cos_reg <= 16'd0;
		  fetch_seen <= 1'b0;
                 
    end

    else begin
	 
	 case (state)

    S_DELAY_FETCH: begin
        
		  prev_ufm_addr <= addr;
        ufm_read_reg <= 1'b0;
        state <= S_FETCH;

	 end
		 
	 S_FETCH: begin
	    
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
								
			  fetch_seen <= 1'b1; 
           cos_reg <= ufm_readdata[15:0];
			  sin_reg <= ufm_readdata[31:16];
           state <= S_DONE;	
			  
       end
		
   end

   S_DONE: begin
		 //While address is unchanged does not fetch next ufm data
	    if(prev_ufm_addr == addr) begin
		 
           state <= S_DONE;
			  
		 end
		 else begin
		     fetch_seen <= 1'b0;
		     state <= S_DELAY_FETCH;
		 end
		 
   end
	
   endcase

	end
	
end

endmodule