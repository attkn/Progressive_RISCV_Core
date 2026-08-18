`timescale 1ns/1ps

module mulTopRTL #(
    parameter int XLEN = 32
)(
    input  logic                 clk_i,
    input  logic                 rst_ni,

    input  logic                 start_i,
    input  logic [1:0]           mode_i,
    input  logic                 flush_i,
    
    input  logic [XLEN-1:0]      in0_i,
    input  logic [XLEN-1:0]      in1_i,

    
    output logic                 done_o,
    output logic [2*XLEN-1:0]    result_o
);

    localparam int NUM_PP = XLEN / 2;

    logic signed [XLEN:0]   in0Extended;
    logic        [XLEN+1:0] in1Extended;

    assign in0Extended = mode_i[0] ? $signed({in0_i[XLEN-1], in0_i}) : $signed({1'b0, in0_i});
    assign in1Extended = mode_i[1] ? {in1_i[XLEN-1], in1_i, 1'b0}   : {1'b0, in1_i, 1'b0};

    logic [2:0] shiftAddMode [NUM_PP-1:0];

    always_comb begin : Recoding
        for (int k = 0; k < NUM_PP; k = k + 1) begin
            logic [2:0] window;
            window = in1Extended[2*k +: 3];

            if (window == 3'b000 || window == 3'b111) begin
                shiftAddMode[k] = 3'd0;
            end else if (window == 3'b001 || window == 3'b010) begin
                shiftAddMode[k] = 3'd1;
            end else if (window == 3'b101 || window == 3'b110) begin
                shiftAddMode[k] = 3'd2;
            end else if (window == 3'b011) begin
                shiftAddMode[k] = 3'd3;
            end else if (window == 3'b100) begin
                shiftAddMode[k] = 3'd4;
            end else begin
                shiftAddMode[k] = 3'd0;
            end
        end
    end

    logic signed [2*XLEN-1:0] shiftAddResult [NUM_PP-1:0];

    generate
        for (genvar i = 0; i < NUM_PP; i = i + 1) begin : shiftAddGen
            subShiftAdder #(
                .XLEN(XLEN)
            ) shiftAdder_ (
                .in_i       (in0Extended),
                .mode_i     (shiftAddMode[i]),
                .shift_idx_i(i),
                .result_o   (shiftAddResult[i])
            );
        end
    endgenerate

    logic signed [2*XLEN-1:0] compressorInput [NUM_PP-1:0];
    logic                     stg1_valid;

    always_ff @(posedge clk_i or negedge rst_ni) begin : compressorStage
        if (!rst_ni || flush_i) begin
            for (int j = 0; j < NUM_PP; j++) begin
                compressorInput[j] <= '0;
            end
            stg1_valid <= 1'b0;
        end else begin
            stg1_valid <= start_i;
            if (start_i) begin
                compressorInput <= shiftAddResult;
            end
        end
    end

    logic [2*XLEN-1:0] s1 [4], c1 [4];
    generate
        for (genvar i = 0; i < 4; i++) begin : layer1Comp
            compressor #(.WIDTH(2*XLEN)) comp1 (
                .in0_i  (compressorInput[4*i + 0]),
                .in1_i  (compressorInput[4*i + 1]),
                .in2_i  (compressorInput[4*i + 2]),
                .in3_i  (compressorInput[4*i + 3]),
                .sum_o  (s1[i]),
                .carry_o(c1[i])
            );
        end
    endgenerate

    logic [2*XLEN-1:0] s2 [2], c2 [2];
    generate
        for (genvar i = 0; i < 2; i++) begin : layer2Comp
            compressor #(.WIDTH(2*XLEN)) comp2 (
                .in0_i  (s1[2*i + 0]),
                .in1_i  (c1[2*i + 0] << 1),
                .in2_i  (s1[2*i + 1]),
                .in3_i  (c1[2*i + 1] << 1),
                .sum_o  (s2[i]),
                .carry_o(c2[i])
            );
        end
    endgenerate

    logic [2*XLEN-1:0] s3, c3;
    compressor #(.WIDTH(2*XLEN)) comp3 (
        .in0_i  (s2[0]),
        .in1_i  (c2[0] << 1),
        .in2_i  (s2[1]),
        .in3_i  (c2[1] << 1),
        .sum_o  (s3),
        .carry_o(c3)
    );

    logic [2*XLEN-1:0] compressorSumOutput;
    logic [2*XLEN-1:0] compressorCarryOut;
    logic              stg2_valid_r;

    always_ff @(posedge clk_i or negedge rst_ni) begin : adderStage
        if (!rst_ni || flush_i) begin
            compressorSumOutput   <= '0;
            compressorCarryOut <= '0;
            stg2_valid_r <= 1'b0;
        end else begin
            stg2_valid_r <= stg1_valid;
            if (stg1_valid) begin
                compressorSumOutput   <= s3;
                compressorCarryOut <= c3;
            end
        end
    end

    always_ff @(posedge clk_i or negedge rst_ni) begin : resultStage
        if (!rst_ni || flush_i) begin
            result_o <= '0;
            done_o   <= 1'b0;
        end else begin
            done_o <= stg2_valid_r;
            if (stg2_valid_r) begin
                result_o <= compressorCarryOut + (compressorSumOutput << 1);
            end
        end
    end

endmodule


module compressor #(
    parameter int WIDTH = 64
)(
    input  logic [WIDTH-1:0] in0_i,
    input  logic [WIDTH-1:0] in1_i,
    input  logic [WIDTH-1:0] in2_i,
    input  logic [WIDTH-1:0] in3_i,
    output logic [WIDTH-1:0] sum_o,
    output logic [WIDTH-1:0] carry_o
);

    logic [WIDTH-1:0] s_mid;
    logic [WIDTH:0]   c_inter;

    assign c_inter[0] = 1'b0;

    generate
        for (genvar k = 0; k < WIDTH; k++) begin : gen_4to2_bits
            assign s_mid[k]     = in0_i[k] ^ in1_i[k] ^ in2_i[k] ^ in3_i[k];
            assign c_inter[k+1] = (in0_i[k] ^ in1_i[k]) ? in2_i[k] : in0_i[k];
            assign sum_o[k]     = s_mid[k] ^ c_inter[k];
            assign carry_o[k]   = s_mid[k] ? c_inter[k] : in3_i[k];
        end
    endgenerate

endmodule


module subShiftAdder #(
    parameter int XLEN = 32
)(
    input  logic signed [XLEN:0]       in_i,
    input  logic [2:0]                 mode_i,
    input  int                         shift_idx_i,
    output logic signed [2*XLEN-1:0]   result_o
);

    logic signed [XLEN+1:0] base_val;

    always_comb begin
        case (mode_i)
            3'd0: base_val = '0;
            3'd1: base_val = in_i;
            3'd2: base_val = ~in_i + 1;
            3'd3: base_val = in_i << 1;
            3'd4: base_val = (~in_i + 1) << 1;
            default: base_val = '0;
        endcase

        result_o = (64'(base_val)) <<< (2 * shift_idx_i);
    end

endmodule
