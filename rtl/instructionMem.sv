`include "riscv_include.svh"

module instructionMemory(
    input logic [XLEN-1:0] readAddress_i,
    output logic [XLEN-1:0] readData_o
);
    logic [XLEN-1:0]mem[INST_MEM_LENGTH-1:0];
    $readmemh("imem.mem" , mem);
    assign readData_o = mem[readAddress_i[31:2]];
endmodule