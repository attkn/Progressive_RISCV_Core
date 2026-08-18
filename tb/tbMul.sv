`timescale 1ns/1ps

module tb_mulTopRTL();

    localparam int XLEN = 32;
    localparam time CLK_PERIOD = 10ns;

    logic                 clk_i;
    logic                 rst_ni;
    logic                 start_i;
    logic [XLEN-1:0]      in0_i;
    logic [XLEN-1:0]      in1_i;
    logic [1:0]           mode_i;
    logic                 done_o;
    logic [2*XLEN-1:0]    result_o;

    mulTopRTL #(
        .XLEN(XLEN)
    ) dut (
        .clk_i   (clk_i),
        .rst_ni  (rst_ni),
        .start_i (start_i),
        .in0_i   (in0_i),
        .in1_i   (in1_i),
        .mode_i  (mode_i),
        .done_o  (done_o),
        .result_o(result_o)
    );

    initial begin
        clk_i = 0;
        forever #(CLK_PERIOD / 2) clk_i = ~clk_i;
    end

    task automatic check_mul(
        input logic [XLEN-1:0] a,
        input logic [XLEN-1:0] b,
        input logic [1:0]      m,
        input string           test_name
    );
        logic signed [2*XLEN-1:0] expected_res;
        
        case (m)
            2'b00: expected_res = 64'({32'b0, a}) * 64'({32'b0, b});
            2'b01: expected_res = 64'($signed(a)) * 64'({32'b0, b});
            2'b10: expected_res = 64'({32'b0, a}) * 64'($signed(b));
            2'b11: expected_res = 64'($signed(a)) * 64'($signed(b));
        endcase

        @(posedge clk_i);
        start_i <= 1'b1;
        in0_i   <= a;
        in1_i   <= b;
        mode_i  <= m;

        @(posedge clk_i);
        start_i <= 1'b0;

        @(posedge clk_i);
        @(posedge clk_i);
        #1;

        if (done_o !== 1'b1) begin
            $display("[FAIL] %-12s | done_o bekleniyordu ama 0 geldi!", test_name);
        end else if (result_o === expected_res) begin
            $display("[PASS] %-12s | Mode: %b | in0: %h, in1: %h | Res: %h", 
                     test_name, m, a, b, result_o);
        end else begin
            $display("[FAIL] %-12s | Mode: %b | in0: %h, in1: %h | Beklenen: %h, Gelen: %h", 
                     test_name, m, a, b, expected_res, result_o);
        end
    endtask

    initial begin
        rst_ni  = 0;
        start_i = 0;
        in0_i   = '0;
        in1_i   = '0;
        mode_i  = '0;
        #(CLK_PERIOD * 2);
        rst_ni  = 1;
        #(CLK_PERIOD);

        check_mul(32'd10, 32'd5, 2'b00, "UU Basit");
        check_mul(32'hFFFF_FFFF, 32'd2, 2'b00, "UU Max In0");
        check_mul(32'hFFFF_FFFF, 32'hFFFF_FFFF, 2'b00, "UU Full Max");

        check_mul(-32'd10, 32'd5, 2'b01, "SU Neg x Poz");
        check_mul(-32'd1, 32'hFFFF_FFFF, 2'b01, "SU -1 x MaxU");

        check_mul(32'd5, -32'd10, 2'b10, "US Poz x Neg");
        check_mul(32'hFFFF_FFFF, -32'd1, 2'b10, "US MaxU x -1");

        check_mul(-32'd2, -32'd3, 2'b11, "SS Neg x Neg");
        check_mul(-32'd10, 32'd5, 2'b11, "SS Neg x Poz");
        check_mul(32'h8000_0000, 32'd1, 2'b11, "SS Min Int");
        check_mul(32'h8000_0000, -32'd1, 2'b11, "SS Min x -1");

        for (int k = 0; k < 20; k++) begin
            check_mul($urandom(), $urandom(), $urandom_range(0, 3), "Rastgele");
        end

        #(CLK_PERIOD * 2);
        $finish;
    end

endmodule