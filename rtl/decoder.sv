module decoder  import riscv_opcodes::*, riscv_types::*;(
    input  logic [XLEN-1:0]   instruction_i,
    output opcode_e           opcode_o,
    output logic [FUNCT7-1:0] funct7_o,
    output logic [FUNCT3-1:0] funct3_o,
    output logic [RS-1:0]     rs1_o,
    output logic [RS-1:0]     rs2_o,
    output logic [SHIFT-1:0]  shift_o,
    output logic [RS-1:0]     rd_o
);

    always_comb begin
        opcode_o = opcode_e'(instruction_i[6:0]);
        rd_o     = instruction_i[11:7];
        funct3_o = instruction_i[14:12];
        rs1_o    = instruction_i[19:15];
        rs2_o    = instruction_i[24:20];
        funct7_o = instruction_i[31:25];
        shift_o  = instruction_i[24:20]; 
    end

endmodule