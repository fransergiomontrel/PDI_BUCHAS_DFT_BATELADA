module luts(

    input clk,
    input rst,
    input [12:0] addr,
    output reg [15:0] sin,
    output reg [15:0] cos

);

reg ufm_read_reg;
wire [31:0] ufm_readdata;
wire ufm_waitrequest;
wire ufm_readdatavalid;

ufm_read u_ufm_read (

    .clock                   (clk),
    .reset_n                 (~rst),

    .avmm_data_addr          (addr),
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

reg[6:0] count_start;

reg [12:0] prev_ufm_addr;

always @(posedge clk) begin

    if (rst) begin
	 
        state <= S_DELAY_FETCH;
        ufm_read_reg <= 1'b0;
        sin <= 16'd0;
		  cos <= 16'd0;
        count_start <= 7'd0;
                 
    end

    else begin
	 
	 case (state)

    S_DELAY_FETCH: begin
        
		  prev_ufm_addr <= addr;
        ufm_read_reg <= 1'b0;
        if (count_start == 7'd50) begin
            count_start <= 7'd0;
            state <= S_FETCH;
        end
		  
        else begin
            count_start <= count_start + 1'b1;
        end

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
                                         
           cos <= ufm_readdata[15:0];
			  sin <= ufm_readdata[31:16];
           state <= S_DONE;
													  
       end
   end

   S_DONE: begin
		 //While address is unchanged does not fetch next ufm data
	    if(prev_ufm_addr == addr) begin
           state <= S_DONE;
		 end
		 else begin
		     state <= S_DELAY_FETCH;
		 end
		 
   end
	
   endcase

	end
	
end

endmodule