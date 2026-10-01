module set_get_ads8691 (
    input  wire clk,
    input  wire rst,      // reset síncrono
	 input wire [31:0] cmd_word,
	 input wire miso_1,
	 input wire miso_2,
	 input wire miso_3,
	 input wire miso_4,
	 input wire miso_5,
	 input wire miso_6,
    output reg  sclk,
    output reg  ncs,
    output reg  mosi,      // saída serial do mestre
	 output wire [95:0] read_half_words,
	 output wire set_get_done_out
);

    reg [5:0] bit_cnt;
    reg [7:0] div_sclk;
    reg [1:0] delay;
	 reg [15:0] miso_buffer_1;
	 reg [15:0] miso_buffer_2;
	 reg [15:0] miso_buffer_3;
	 reg [15:0] miso_buffer_4;
	 reg [15:0] miso_buffer_5;
	 reg [15:0] miso_buffer_6;
	 
	 reg set_get_done_reg;
	 
	 assign read_half_words = {miso_buffer_6, miso_buffer_5, miso_buffer_4, miso_buffer_3, miso_buffer_2, miso_buffer_1};
	 assign set_get_done_out = set_get_done_reg;
	 
	 
	 localparam READ_COMMAND = 5'b11001;
    // Definição dos estados
    localparam LOAD_WORD            = 4'b0000;
    localparam CHIP_SELECTED        = 4'b0001;
    localparam TSU_CSCK_MOSI        = 4'b0010;
    localparam AWAIT_SCLK_FALL_MOSI = 4'b0011;
    localparam AWAIT_SCLK_RISE_MOSI = 4'b0100;
    localparam LOAD_NEXT_WORD       = 4'b0101;
    localparam IDLE                 = 4'b0110;

    reg [3:0] current_spi_state;

    always @(posedge clk) begin
        if (rst) begin
		  
            sclk <= 1'b0;
            ncs  <= 1'b1;
            mosi <= 1'b0;

            div_sclk <= 8'd0;
            delay    <= 2'd0;
            bit_cnt  <= 6'd31;
				miso_buffer_1 <= 16'h0000;
				miso_buffer_2 <= 16'h0000;
				miso_buffer_3 <= 16'h0000;
				miso_buffer_4 <= 16'h0000;
				miso_buffer_5 <= 16'h0000;
				miso_buffer_6 <= 16'h0000;
				
            set_get_done_reg <= 1'b0;

            current_spi_state <= LOAD_WORD;
				
        end
        else begin
		  
				
            case (current_spi_state)

                // Após sair do reset, já inicia automaticamente
                LOAD_WORD: begin
					 
					     mosi <= cmd_word[bit_cnt];
                    ncs <= 1'b0;
                    sclk <= 1'b0;
                    current_spi_state <= CHIP_SELECTED;
						  
                end

                // Carrega a primeira palavra e já posiciona o MSB em MOSI
                CHIP_SELECTED: begin
                    
                   
                    delay <= 2'd0;
                    current_spi_state <= TSU_CSCK_MOSI;
						  
                end

                // Garante tempo entre nCS cair e a primeira subida de SCLK
                TSU_CSCK_MOSI: begin
                    delay <= delay + 2'd1;

                    if (delay == 2'd3) begin
                        delay <= 2'd0;
                        sclk <= 1'b1;   // em SPI modo 0, o ADC captura aqui
                        current_spi_state <= AWAIT_SCLK_FALL_MOSI;
                    end
                    else begin
                        current_spi_state <= TSU_CSCK_MOSI;
                    end
                end

                // Espera e depois derruba SCLK
                // Em SPI modo 0, na descida do clock preparamos o próximo bit
                AWAIT_SCLK_FALL_MOSI: begin
                    div_sclk <= div_sclk + 8'd1;

                    if (div_sclk == 8'd49) begin
                        div_sclk <= 8'd0;
                        sclk <= 1'b0;

                        if (bit_cnt == 6'd0) begin
								
                            // terminou a palavra atual de 32 bits
                            bit_cnt <= 6'd31;
                            mosi <= 1'b0;
									 set_get_done_reg <= 1'b1;
									 current_spi_state <= IDLE;
     
                        end
                        else begin
								
                            // prepara o próximo bit enquanto SCLK está em LOW                 
                            bit_cnt <= bit_cnt - 1;
                            current_spi_state <= AWAIT_SCLK_RISE_MOSI;
									 
                        end
                    end
                    else begin
						      //A partir do 16°clock apos cada sclk rising 
						      if ((bit_cnt < 6'd16) && (cmd_word[31:27] == READ_COMMAND)) begin
								
									 miso_buffer_1[bit_cnt] <= miso_1;
									 miso_buffer_2[bit_cnt] <= miso_2;
									 miso_buffer_3[bit_cnt] <= miso_3;
									 miso_buffer_4[bit_cnt] <= miso_4;
									 miso_buffer_5[bit_cnt] <= miso_5;
									 miso_buffer_6[bit_cnt] <= miso_6;
									 
							   end
								
                        current_spi_state <= AWAIT_SCLK_FALL_MOSI;
                    end
                end

                // Espera e depois sobe SCLK
                // Em SPI modo 0, o escravo captura nessa subida
                AWAIT_SCLK_RISE_MOSI: begin
                    div_sclk <= div_sclk + 8'd1;
						  mosi <= cmd_word[bit_cnt];
                    if (div_sclk == 8'd49) begin
                        div_sclk <= 8'd0;
                        sclk <= 1'b1;
                        current_spi_state <= AWAIT_SCLK_FALL_MOSI;
                    end
                    else begin
                        current_spi_state <= AWAIT_SCLK_RISE_MOSI;
                    end
                end


                // Estado final
                IDLE: begin
                    ncs <= 1'b1;
                    sclk <= 1'b0;
                    mosi <= 1'b0;
                    current_spi_state <= IDLE;
                end

                default: begin
                    sclk <= 1'b0;
                    ncs <= 1'b1;
                    mosi <= 1'b0;
                    current_spi_state <= IDLE;
                end

            endcase
        end
    end

endmodule
