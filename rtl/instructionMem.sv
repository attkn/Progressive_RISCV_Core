`include "riscv_include.svh"

module instructionMemoryRTL(
    input logic clk_i,
    input logic rst_ni,
    input logic [XLEN-1:0] readAddress_i,
    output logic [XLEN-1:0] readData_o
);
    logic [XLEN-1:0]mem[INST_MEM_LENGTH-1:0];
    assign readData_o = mem[readAddress_i];
endmodule