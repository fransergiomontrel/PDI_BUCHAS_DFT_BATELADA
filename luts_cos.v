module cos(
input [12:0] addr,
output reg signed [15:0] cossine
);

reg signed [15:0] cossine_lut[0:7215];

initial begin
    $readmemh("cos_7215_16bits.hex", cossine_lut);
end

always @(*) begin

    cossine = cossine_lut[addr];

end

endmodule