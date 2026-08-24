module immGenerator
    import riscv_opcodes::*, riscv_types::*;
#(
    parameter int unsigned XLEN = 32
) (
    input  imm_type_e         immType_i,
    input  logic      [31:0] instr_i,
    output logic [XLEN-1:0]  imm_o
);

    logic [31:0] imm_i_type;
    logic [31:0] imm_s_type;
    logic [31:0] imm_b_type;
    logic [31:0] imm_u_type;
    logic [31:0] imm_j_type;
    logic [31:0] imm_z_type;
    logic [31:0] imm_sel;

    assign imm_i_type = {{20{instr_i[31]}}, instr_i[31:20]};

    assign imm_s_type = {{20{instr_i[31]}}, instr_i[31:25], instr_i[11:7]};

    assign imm_b_type = {{19{instr_i[31]}}, instr_i[31], instr_i[7],
                         instr_i[30:25], instr_i[11:8], 1'b0};

    assign imm_u_type = {instr_i[31:12], 12'b0};

    assign imm_j_type = {{11{instr_i[31]}}, instr_i[31], instr_i[19:12],
                         instr_i[20], instr_i[30:21], 1'b0};

    assign imm_z_type = {27'b0, instr_i[19:15]};

    always_comb begin
        unique case (immType_i)
            IMM_I : imm_sel = imm_i_type;
            IMM_S : imm_sel = imm_s_type;
            IMM_B : imm_sel = imm_b_type;
            IMM_U : imm_sel = imm_u_type;
            IMM_J : imm_sel = imm_j_type;
            IMM_Z : imm_sel = imm_z_type;
            default: imm_sel = '0;
        endcase
    end

    assign imm_o = XLEN'($signed(imm_sel));
endmodule