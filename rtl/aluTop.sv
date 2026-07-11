import riscv_pkg::*;
module aluTopRTL(
    input   logic   clk_i,
    input   logic   rst_ni,

    input   logic   [WIDTH-1:0] rd1_i,
    input   logic   [WIDTH-1:0] rd2_i,
    input   logic   [WIDTH-1:0] rd3_i,
    input   logic   [5:0]       intShiftSize,

    input   alu_op_int_e    aluOperationInt_i,
    input   alu_op_mul_e    aluOperationMul_i,
    input   alu_op_div_e    aluOperationDiv_i,
    input   alu_op_branch_e aluOperationBranch_i,
    input   logic           startInt_i,
    input   logic           startMul_i,
    input   logic           startDiv_i,
    input   logic           startBranch_i,
    input   logic           resultMulHigh_i,

    output  logic   doneMul_o,
    output  logic   doneDiv_o,

    output  logic   busy_o, 
    
    output  logic   [WIDTH-1:0]result_o,
    output  logic   branchTaken_o
); 


    logic   [WIDTH-1:0] intResult;
    logic   [WIDTH-1:0] mulResult;
    logic   [WIDTH-1:0] divQauntient;
    logic   [WIDTH-1:0] divRemainder;
    logic   [WIDTH-1:0] branchResult;

    logic               tempDivDone;
    logic               tempMulDone;

    aluIntRTL intUnit(
        .aluModeInt_i(aluOperationInt_i),
        .rd1_i(rd1_i),
        .rd2_i(rd2_i),
        .shift_size(intShiftSize),
        .result_o(intResult)
    );

    aluBranchRTL branchUnit(
        .brOp_i(aluOperationBranch_i),
        .rd1_i(rd1_i),
        .rd2_i(rd2_i),
        .branchTaken_o(branchResult)
    );

    dividerRTL dividerUnit(
        .clk_i(clk_i),
        .rst_ni(rst_ni),
        .mode_i(aluOperationDiv_i),
        .start_i(startDiv_i),
        .dividend_i(rd1_i),
        .divider_i(rd2_i),
        .remainder_i(divRemainder),
        .quantient_i(divQauntient),
        .done_i(tempDivDone)
    );

    multiplierRTL multiplierUnit(
        .clk_i(clk_i),
        .rst_ni(rst_ni),
        .rd1_i(rd1_i),
        .rd2_i(rd2_i),
        .mode_i(aluOperationMul_i),
        .start_i(startMul_i),
        .resultHigh_i(resultMulHigh_i),
        .done_o(tempMulDone),
        .result_o(mulResult)
    );

    logic edgeDetectionStartMul;
    logic edgeDetectionStartDiv;

    logic runMul;
    logic runDiv;

    


endmodule
