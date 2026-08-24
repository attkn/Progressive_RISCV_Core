`include "riscv_imports.svh"
module aluBranch #(parameter int WIDTH = 32)(
  input  branch_op_e       brOp_i,
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
      BR_EQ : branchTaken_o =  eq;
      BR_NE : branchTaken_o = !eq;
      BR_LT : branchTaken_o =  lt_s;
      BR_GE : branchTaken_o = !lt_s;
      BR_LTU: branchTaken_o =  lt_u;
      BR_GEU: branchTaken_o = !lt_u;
      default : branchTaken_o = 0;
    endcase
  end
endmodule
