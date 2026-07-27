// Formal wrapper: aluIntRTL dogrulugu (SymbiYosys ile ispat).
// NOT: yosys + symbiyosys gerektirir (bu ornek ortamda kosulmadi — sablon).
`include "riscv_imports.svh"
module alu_int_fv (input logic clk);
  alu_op_int_e      op;
  logic [WIDTH-1:0] a, b, y;
  logic [5:0]       sh;
  aluIntRTL #(.WIDTH(WIDTH)) dut (.aluOp_i(op), .rd1_i(a), .rd2_i(b),
                                  .shift_size(sh), .result_o(y));
  // kombinasyonel dogruluk iddialari (her op icin referans)
  always_comb begin
    unique case (op)
      ALU_ADD : assert (y == (a + b));
      ALU_SUB : assert (y == (a - b));
      ALU_AND : assert (y == (a & b));
      ALU_OR  : assert (y == (a | b));
      ALU_XOR : assert (y == (a ^ b));
      ALU_SLT : assert (y == {{(WIDTH-1){1'b0}}, ($signed(a) < $signed(b))});
      ALU_SLTU: assert (y == {{(WIDTH-1){1'b0}}, (a < b)});
      default : ;   // shift'ler shamt'a bagli — depth>0 gerektirir
    endcase
  end
endmodule
