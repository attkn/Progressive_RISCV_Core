`timescale 1ns / 1ps

module tb_divUnitRTL;

    logic        clk_i;
    logic        rst_ni;
    logic        flush_i;
    logic        mode_i;
    logic        start_i;
    logic [31:0] dividend_i;
    logic [31:0] divisor_i;
    logic [31:0] quotient_o;
    logic [31:0] remainder_o;
    logic        done_o;

    int passCount = 0;
    int failCount = 0;

    divUnitRTL dut (
        .clk_i       (clk_i),
        .rst_ni      (rst_ni),
        .flush_i     (flush_i),
        .mode_i      (mode_i),
        .start_i     (start_i),
        .dividend_i  (dividend_i),
        .divisor_i   (divisor_i),
        .quotient_o  (quotient_o),
        .remainder_o (remainder_o),
        .done_o      (done_o)
    );

    always #5 clk_i = ~clk_i;

    task automatic runCornerTest(
        input logic        mode,
        input logic [31:0] dividend,
        input logic [31:0] divisor,
        input logic [31:0] expQuotient,
        input logic [31:0] expRemainder
    );
        @(posedge clk_i);
        mode_i     <= mode;
        dividend_i <= dividend;
        divisor_i  <= divisor;
        start_i    <= 1'b1;

        @(posedge clk_i);
        start_i    <= 1'b0;

        @(posedge clk_i iff done_o);

        if (quotient_o === expQuotient && remainder_o === expRemainder) begin
            $display("[PASS] Mode: %-8s | In: (%0h, %0h) | Q: %0h (Exp: %0h), R: %0h (Exp: %0h)",
                     mode ? "UNSIGNED" : "SIGNED",
                     dividend, divisor, quotient_o, expQuotient, remainder_o, expRemainder);
            passCount++;
        end else begin
            $display("[FAIL] Mode: %-8s | In: (%0h, %0h) | Got Q: %0h, R: %0h | Exp Q: %0h, R: %0h",
                     mode ? "UNSIGNED" : "SIGNED",
                     dividend, divisor, quotient_o, remainder_o, expQuotient, expRemainder);
            failCount++;
        end
        @(posedge clk_i);
    endtask

    initial begin
        clk_i      = 0;
        rst_ni     = 0;
        flush_i    = 0;
        mode_i     = 0;
        start_i    = 0;
        dividend_i = 0;
        divisor_i  = 0;

        #20;
        rst_ni = 1;
        #20;

        // Division by Zero (Unsigned: DIVU, REMU) -> Q = 2^L - 1, R = x
        runCornerTest(1'b1, 32'd12345, 32'd0, 32'hFFFF_FFFF, 32'd12345);

        // Division by Zero (Signed: DIV, REM) -> Q = -1, R = x
        runCornerTest(1'b0, 32'd54321, 32'd0, 32'hFFFF_FFFF, 32'd54321);
        runCornerTest(1'b0, -32'd54321, 32'd0, 32'hFFFF_FFFF, -32'd54321);

        // Overflow (Signed only: -2^(L-1) / -1) -> Q = -2^(L-1), R = 0
        runCornerTest(1'b0, 32'h8000_0000, 32'hFFFF_FFFF, 32'h8000_0000, 32'h0000_0000);

        // Normal Cases
        runCornerTest(1'b1, 32'd100, 32'd10, 32'd10, 32'd0);
        runCornerTest(1'b0, -32'd7, 32'd3, -32'd2, -32'd1);

        #50;
        $display("\n=================================");
        $display("TEST SONUCLARI: PASS = %0d, FAIL = %0d", passCount, failCount);
        $display("=================================");
        $finish;
    end

endmodule