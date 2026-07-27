`include "riscv_imports.svh"
// x0 = 0. 2 okuma / 1 yazma. Kombinasyonel oku, kenarda yaz (single-cycle).
module regFileRTL (
  input  logic clk_i, rst_ni,
  input  logic [RS_ADDRESS-1:0] rs1_addr_i, rs2_addr_i, rd_addr_i,
  input  logic [WIDTH-1:0]      rd_wdata_i,
  input  logic                  rd_we_i,
  output logic [WIDTH-1:0]      rs1_val_o, rs2_val_o
);
  logic [WIDTH-1:0] regs [0:(1<<RS_ADDRESS)-1];
  integer i;
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) for (i=0;i<(1<<RS_ADDRESS);i++) regs[i] <= '0;
    else if (rd_we_i && (rd_addr_i != '0)) regs[rd_addr_i] <= rd_wdata_i;
  end
  assign rs1_val_o = (rs1_addr_i=='0) ? '0 : regs[rs1_addr_i];
  assign rs2_val_o = (rs2_addr_i=='0) ? '0 : regs[rs2_addr_i];
endmodule
