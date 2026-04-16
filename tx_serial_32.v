module tx_serial_32 (
    input  wire        clk,
    input  wire        rst,       // reset síncrono
    input  wire        start,     // inicia transmissão
    input  wire [31:0] data_in,   // dado paralelo
    output reg         tx,        // saída serial
    output reg         busy,      // está transmitindo
    output reg         done       // pulso de fim
);

    reg [31:0] shift_reg; 
    reg [5:0]  bit_cnt; // precisa contar até 32
	 reg [9:0]  tx_freq_divider;// register to calculate boud rate = 100MHz/tx_freq_divider

    always @(posedge clk) begin
        if (rst) begin
            shift_reg <= 32'd0;
            bit_cnt   <= 6'd0;
            tx        <= 1'b0;
            busy      <= 1'b0;
            done      <= 1'b0;
				tx_freq_divider  <= 10'd0;
        end else begin
            done <= 1'b0; // default

            // inicia transmissão
            if (start && !busy) begin
                shift_reg <= data_in;
                bit_cnt   <= 6'd32;
                busy      <= 1'b1;
            end 
            // transmissão em andamento
            else if (busy) begin
				    tx_freq_divider  <= tx_freq_divider + 10'd1;
					 if (tx_freq_divider == 10'd868) begin //boud rate
                    tx        <= shift_reg[0];        // envia LSB
                    shift_reg <= shift_reg >> 1;      // shift
                    bit_cnt   <= bit_cnt - 1;
						  tx_freq_divider  <= 10'd0;
					 end
					 
                if (bit_cnt == 1) begin
                    busy <= 1'b0;
                    done <= 1'b1; // terminou neste ciclo
                end
            end
        end
    end

endmodule