`include "riscv_imports.svh"
module pcRTL (
  input  logic        clk_i, rst_ni,
  input  logic [WIDTH-1:0] next_i,
  output logic [WIDTH-1:0] pc_o
);
  logic [WIDTH-1:0] pc_q;
  always_ff @(posedge clk_i or negedge rst_ni)
    if (!rst_ni) pc_q <= RESET_ADDR;
    else         pc_q <= next_i;
  assign pc_o = pc_q;
endmodule
