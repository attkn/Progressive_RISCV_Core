`timescale 1ns/1ps

module tb_mulTopRTL();

    localparam int XLEN = 32;
    localparam int MODE = 4;

    logic [XLEN-1:0]     in0_i;
    logic [XLEN-1:0]     in1_i;
    logic [MODE-1:0]     mode_i;
    logic [(XLEN*2)-1:0] result_o;

    // DUT Örnekleme
    mulTopRTL #(
        .XLEN(XLEN),
        .MODE(MODE)
    ) dut (
        .in0_i   (in0_i),
        .in1_i   (in1_i),
        .mode_i  (mode_i),
        .result_o(result_o)
    );

    // Test Senaryoları
    initial begin
        // Başlangıç değerleri
        in0_i  = '0;
        in1_i  = '0;
        mode_i = '0;
        #10;

        // Mode 00: Unsigned x Unsigned (uu)
        mode_i = 4'b0000;
        in0_i  = 32'd10;
        in1_i  = 32'd5;
        #10;
        $display("[uu] in0: %h, in1: %h | result_o: %h (%0d)", in0_i, in1_i, result_o, result_o);

        in0_i  = 32'hFFFF_FFFF;
        in1_i  = 32'd2;
        #10;
        $display("[uu] in0: %h, in1: %h | result_o: %h (%0d)", in0_i, in1_i, result_o, result_o);

        // Mode 01: Unsigned x Signed (us)
        mode_i = 4'b0001;
        in0_i  = 32'd10;
        in1_i  = -32'd5;
        #10;
        $display("[us] in0: %h, in1: %h | result_o: %h (%0d)", in0_i, in1_i, result_o, $signed(result_o));

        // Mode 10: Signed x Unsigned (su)
        mode_i = 4'b0010;
        in0_i  = -32'd10;
        in1_i  = 32'd5;
        #10;
        $display("[su] in0: %h, in1: %h | result_o: %h (%0d)", in0_i, in1_i, result_o, $signed(result_o));

        // Mode 11: Signed x Signed (ss)
        mode_i = 4'b0011;
        in0_i  = -32'd10;
        in1_i  = -32'd5;
        #10;
        $display("[ss] in0: %h, in1: %h | result_o: %h (%0d)", in0_i, in1_i, result_o, $signed(result_o));

        in0_i  = 32'h7FFF_FFFF;
        in1_i  = 32'h7FFF_FFFF;
        #10;
        $display("[ss] in0: %h, in1: %h | result_o: %h (%0d)", in0_i, in1_i, result_o, $signed(result_o));

        // Ekstra rastgele değer denemeleri
        for (int m = 0; m < 4; m++) begin
            mode_i = m;
            for (int k = 0; k < 3; k++) begin
                in0_i = $urandom();
                in1_i = $urandom();
                #10;
                $display("[Mode %0b] in0: %h, in1: %h | result_o: %h", mode_i[1:0], in0_i, in1_i, result_o);
            end
        end

        #20;
        $finish;
    end

endmodule