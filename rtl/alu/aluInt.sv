`include "riscv_imports.svh"
module aluIntRTL #(parameter int WIDTH = 32)(
  input  alu_op_int_e      aluOp_i,
  input  logic [WIDTH-1:0] rd1_i, rd2_i,
  input  logic [5:0]       shift_size,
  output logic [WIDTH-1:0] result_o
);
  localparam int SHAMT_W = $clog2(WIDTH);
  logic [SHAMT_W-1:0] shamt; assign shamt = shift_size[SHAMT_W-1:0];
  always_comb begin
    result_o = '0;
    unique case (aluOp_i)
      ALU_ADD : result_o = rd1_i + rd2_i;
      ALU_SUB : result_o = rd1_i - rd2_i;
      ALU_AND : result_o = rd1_i & rd2_i;
      ALU_OR  : result_o = rd1_i | rd2_i;
      ALU_XOR : result_o = rd1_i ^ rd2_i;
      ALU_SLL : result_o = rd1_i << shamt;
      ALU_SRL : result_o = rd1_i >> shamt;
      ALU_SRA : result_o = $unsigned($signed(rd1_i) >>> shamt);
      ALU_SLT : result_o = {{(WIDTH-1){1'b0}}, ($signed(rd1_i) < $signed(rd2_i))};
      ALU_SLTU: result_o = {{(WIDTH-1){1'b0}}, (rd1_i < rd2_i)};
      default : ;
    endcase
  end
endmodule
