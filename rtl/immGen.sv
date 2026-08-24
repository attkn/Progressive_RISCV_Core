module immGen import riscv_pkg::*; #(parameter int WIDTH = 32) (
    input  logic [31:0]      instr_i,
    input  imm_type_e        immType_i,
    output logic [WIDTH-1:0] imm_o
);

    logic signBit;
    assign signBit = instr_i[IMM_SIGN_BIT];   // her formatta ayni yerde

    always_comb begin
        case (immType_i)

            // instr[31:20]
            IMM_I : imm_o = {{20{signBit}}, instr_i[IMM_I_MSB:IMM_I_LSB]};

            // instr[31:25] + instr[11:7]
            IMM_S : imm_o = {{20{signBit}},
                             instr_i[IMM_S_HI_MSB:IMM_S_HI_LSB],
                             instr_i[IMM_S_LO_MSB:IMM_S_LO_LSB]};

            // {instr[31], instr[7], instr[30:25], instr[11:8], 1'b0}
            IMM_B : imm_o = {{20{signBit}},                          // imm[31:12]
                             instr_i[IMM_B_BIT11],                   // imm[11]
                             instr_i[IMM_B_HI_MSB:IMM_B_HI_LSB],     // imm[10:5]
                             instr_i[IMM_B_LO_MSB:IMM_B_LO_LSB],     // imm[4:1]
                             1'b0};                                  // imm[0] = 0

            // instr[31:12] << 12
            IMM_U : imm_o = {instr_i[IMM_U_MSB:IMM_U_LSB], 12'b0};

            // {instr[31], instr[19:12], instr[20], instr[30:21], 1'b0}
            IMM_J : imm_o = {{12{signBit}},                          // imm[31:20]
                             instr_i[IMM_J_HI_MSB:IMM_J_HI_LSB],     // imm[19:12]
                             instr_i[IMM_J_BIT11],                   // imm[11]
                             instr_i[IMM_J_LO_MSB:IMM_J_LO_LSB],     // imm[10:1]
                             1'b0};                                  // imm[0] = 0

            // Zicsr: SIFIR uzatma -- isaret uzatma DEGIL
            IMM_Z : imm_o = {{27{1'b0}}, instr_i[IMM_Z_MSB:IMM_Z_LSB]};

            default : imm_o = '0;   // IMM_NONE
        endcase
    end

endmodule
