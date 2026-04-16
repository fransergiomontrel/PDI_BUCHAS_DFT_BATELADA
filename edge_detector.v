
module edge_detector(
  input current_read_pulse,
  input clk,
  output reg rising_edge,
  input reset
);
reg previous_read_pulse;
  

  always @(posedge clk, posedge reset) begin
    if(reset) begin
      rising_edge = 1'b0;
		previous_read_pulse = 1'b0;
    end
    else begin
      previous_read_pulse <= current_read_pulse;
		//Check on each rising edge of clock if there was rising in read_pulse
		rising_edge <= current_read_pulse & ~previous_read_pulse;
    end
  end // always
endmodule // crc


