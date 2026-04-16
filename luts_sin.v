
module sin(
input [12:0] addr,
output reg signed [15:0] sine
);

reg signed [15:0] sine_lut[0:7215];

initial begin
    $readmemh("seno_7215_16bits.hex", sine_lut);
end

always @(*) begin

    sine = sine_lut[addr];

end

endmodule