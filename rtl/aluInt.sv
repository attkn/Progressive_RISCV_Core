import riscv_pkg::*;   // alu_mode_int_e

module aluIntRTL #(
  parameter int WIDTH = 32
)(
  input  alu_mode_int_e    aluModeInt_i,

  input  logic [WIDTH-1:0] rd1_i,
  input  logic [WIDTH-1:0] rd2_i,
  input  logic [5:0]       shift_size,   // shamt kaynağı (RV32: alt 5 bit)

  output logic [WIDTH-1:0] result_o,
  output logic             branchTaken_o // branch koşulu sağlandıysa 1
);

  localparam int SHAMT_W = $clog2(WIDTH);           // RV32 -> 5
  logic [SHAMT_W-1:0] shamt;
  assign shamt = shift_size[SHAMT_W-1:0];
// ============================================================================
//  aluIntRTL : RV32I tamsayı ALU — sadece aritmetik/mantık (branch AYRI)
//  Tek-cycle, kombinasyonel. rd1_i/rd2_i = mux'lanmış operandlar
//  (R-type: rs1/rs2 · ADDI: rs1/imm · branch hedefi: PC/imm · AUIPC: PC/imm ...).
// ============================================================================
import riscv_pkg::*;   // alu_op_e

module aluIntRTL #(
  parameter int WIDTH = 32
)(
  input  alu_op_e          aluOp_i,
  input  logic [WIDTH-1:0] rd1_i,        // operand A
  input  logic [WIDTH-1:0] rd2_i,        // operand B
  input  logic [5:0]       shift_size,   // shamt kaynağı (RV32: alt 5 bit)
  output logic [WIDTH-1:0] result_o
);

  localparam int SHAMT_W = $clog2(WIDTH);           // RV32 -> 5
  logic [SHAMT_W-1:0] shamt;
  assign shamt = shift_size[SHAMT_W-1:0];

  always_comb begin
    result_o = '0;
    unique case (aluOp_i)
      ALU_ADD : result_o = rd1_i + rd2_i;
      ALU_SUB : result_o = rd1_i - rd2_i;
      ALU_AND : result_o = rd1_i & rd2_i;
      ALU_OR  : result_o = rd1_i | rd2_i;
      ALU_XOR : result_o = rd1_i ^ rd2_i;
      ALU_SLL : result_o = rd1_i << shamt;
      ALU_SRL : result_o = rd1_i >> shamt;                       // mantıksal
      ALU_SRA : result_o = $unsigned($signed(rd1_i) >>> shamt);  // aritmetik
      ALU_SLT : result_o = {{(WIDTH-1){1'b0}}, ($signed(rd1_i) < $signed(rd2_i))};
      ALU_SLTU: result_o = {{(WIDTH-1){1'b0}}, (rd1_i < rd2_i)};
      default : ;
    endcase
  end

endmodule
  // paylaşılan karşılaştırma primitifleri
  logic eq, lt_s, lt_u;
  assign eq   = (rd1_i == rd2_i);
  assign lt_s = ($signed(rd1_i) < $signed(rd2_i));  // işaretli <
  assign lt_u = (rd1_i < rd2_i);                     // işaretsiz <

  always_comb begin
    result_o      = '0;
    branchTaken_o = 1'b0;
    unique case (aluModeInt_i)
      // --- aritmetik / mantık -> result_o ---
      ALU_ADD : result_o = rd1_i + rd2_i;
      ALU_SUB : result_o = rd1_i - rd2_i;
      ALU_AND : result_o = rd1_i & rd2_i;
      ALU_OR  : result_o = rd1_i | rd2_i;
      ALU_XOR : result_o = rd1_i ^ rd2_i;
      ALU_SLL : result_o = rd1_i << shamt;
      ALU_SRL : result_o = rd1_i >> shamt;                       // mantıksal
      ALU_SRA : result_o = $unsigned($signed(rd1_i) >>> shamt);  // aritmetik
      ALU_SLT : result_o = {{(WIDTH-1){1'b0}}, lt_s};
      ALU_SLTU: result_o = {{(WIDTH-1){1'b0}}, lt_u};
      // --- branch karşılaştırmaları -> branchTaken_o ---
      ALU_BEQ : branchTaken_o =  eq;
      ALU_BNE : branchTaken_o = !eq;
      ALU_BLT : branchTaken_o =  lt_s;
      ALU_BGE : branchTaken_o = !lt_s;
      ALU_BLTU: branchTaken_o =  lt_u;
      ALU_BGEU: branchTaken_o = !lt_u;
      default : ; // result_o=0, branchTaken_o=0 (yukarıda atandı)
    endcase
  end

endmodule