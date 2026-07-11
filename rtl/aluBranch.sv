// ============================================================================
//  branchCmpRTL : branch koşulu komparatörü (ALU'dan AYRI)
//  Tek-cycle, kombinasyonel. HAM rs1/rs2 ile beslenir (mux'lanmamış), çünkü
//  branch komutunda ALU hedefi (PC+imm) hesaplarken bu birim koşulu değerlendirir.
//  brOp_i doğrudan funct3 (inst[14:12]) olabilir — enum onunla aynı kodlanmış.
// ============================================================================
import riscv_pkg::*;   // branch_op_e

module branchCmpRTL #(
  parameter int WIDTH = 32
)(
  input  branch_op_e       brOp_i,
  input  logic [WIDTH-1:0] rd1_i,        // ham rs1
  input  logic [WIDTH-1:0] rd2_i,        // ham rs2
  output logic             branchTaken_o
);

  // paylaşılan karşılaştırma primitifleri
  logic eq, lt_s, lt_u;
  assign eq   = (rs1_i == rd2_i);
  assign lt_s = ($signed(rd1_i) < $signed(rd2_i));  // işaretli <
  assign lt_u = (rd1_i < rd2_i);                     // işaretsiz <

  always_comb begin
    branchTaken_o = 1'b0;
    unique case (brOp_i)
      BR_EQ : branchTaken_o =  eq;
      BR_NE : branchTaken_o = !eq;
      BR_LT : branchTaken_o =  lt_s;
      BR_GE : branchTaken_o = !lt_s;
      BR_LTU: branchTaken_o =  lt_u;
      BR_GEU: branchTaken_o = !lt_u;
      default : ;   // geçersiz funct3 (010/011) -> taken değil
    endcase
  end

endmodule