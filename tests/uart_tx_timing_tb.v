`timescale 1ns/1ps
module uart_tx_timing_tb;
    reg clk = 0;
    always #5 clk = ~clk;
    reg rst = 1, start = 0;
    reg [575:0] data_in = 0;
    wire tx, busy, done, ref_tx, ref_busy, ref_done;
    integer cycles = 0;
    integer frame, j, n;
    reg [15:0] expected;
    reg [15:0] sums [0:3];
    integer valid = 0;
    uart_tx dut(clk, rst, start, data_in, tx, busy, done);
    uart_tx_reference reference_uart(clk, rst, start, data_in, ref_tx, ref_busy, ref_done);

    // Independent byte sum; verifies pipeline with changing inputs, not only frames.
    always @(posedge clk) begin
        cycles = cycles + 1;
        if (rst) valid = 0;
        else begin
            sums[3] = sums[2]; sums[2] = sums[1]; sums[1] = sums[0];
            expected = 0;
            for (n = 0; n < 72; n = n + 1)
                expected = expected + data_in[n*8 +: 8];
            sums[0] = expected;
            valid = valid + 1;
        end
        #1;
        if ({tx,busy,done} !== {ref_tx,ref_busy,ref_done})
            $fatal(1, "UART differs at cycle %0d", cycles);
        if (valid >= 4 && dut.sum_reg !== sums[3])
            $fatal(1, "Checksum pipeline differs at cycle %0d", cycles);
        if (cycles > 6000000) $fatal(1, "Simulation timeout");
    end

    task send_frame;
        begin
            start = 1;
            @(negedge clk); start = 0;
            wait (done); @(negedge clk);
            repeat (8) @(negedge clk);
        end
    endtask

    initial begin
        repeat (4) @(negedge clk);
        rst = 0;
        // Arbitrary changes while idle, including carries across checksum bytes.
        for (j = 0; j < 1000; j = j + 1) begin
            for (frame = 0; frame < 18; frame = frame + 1)
                data_in[frame*32 +: 32] = $random;
            @(negedge clk);
        end
        // No idle warm-up required when data and start arrive together.
        data_in = 0; send_frame;
        data_in = {576{1'b1}}; send_frame;
        for (frame = 0; frame < 4; frame = frame + 1) begin
            for (j = 0; j < 18; j = j + 1) data_in[j*32 +: 32] = $random;
            send_frame;
        end
        // Abort a frame, reset, then restart with a different payload.
        start = 1;
        @(negedge clk); start = 0;
        repeat (20000) @(negedge clk);
        rst = 1;
        repeat (4) @(negedge clk);
        rst = 0;
        data_in = {72{8'ha5}}; send_frame;
        $display("PASS: 7 complete frames, reset/restart, %0d cycles; UART outputs identical", cycles);
        $finish;
    end
endmodule
