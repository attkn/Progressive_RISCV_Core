module instructionMemory import riscv_opcodes::*, riscv_types::*; (
    input logic [XLEN-1:0] readAddress_i,
    output logic [XLEN-1:0] readData_o
);
    logic [XLEN-1:0]mem[INST_MEM_LENGTH-1:0];
    initial begin
        $readmemh("imem.mem" , mem);
    end
    assign readData_o = mem[readAddress_i[31:2]];
endmodule