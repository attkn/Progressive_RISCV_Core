module aluBranch import riscv_opcodes::*, riscv_types::*;
 #(parameter int WIDTH = 32)(
  input  aluOpBranch_e       brOp_i,
  input  logic [WIDTH-1:0] rd1_i, rd2_i,
  output logic             branchTaken_o
);
  logic eq, lt_s, lt_u;
  assign eq   = (rd1_i == rd2_i);
  assign lt_s = ($signed(rd1_i) < $signed(rd2_i));
  assign lt_u = (rd1_i < rd2_i);
  always_comb begin
    branchTaken_o = 1'b0;
    unique case (brOp_i)
      ALU_BEQ : branchTaken_o =  eq;
      ALU_BNE : branchTaken_o = !eq;
      ALU_BLT : branchTaken_o =  lt_s;
      ALU_BGE : branchTaken_o = !lt_s;
      ALU_BLTU: branchTaken_o =  lt_u;
      ALU_BGEU: branchTaken_o = !lt_u;
      default : branchTaken_o = 0;
    endcase
  end
endmodule
