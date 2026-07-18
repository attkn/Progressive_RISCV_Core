// ============================================================================
//  decoderRTL : komut alanı çıkarımı + immediate üretimi
//  (senin modülün bitirildi: genişlikler, funct7, imm eklendi)
//  Sonraki adım: opcode/funct3/funct7 -> tam kontrol sinyalleri (alu_op,
//  reg_write, mem_read/write, unit_sel...). Şimdilik alanlar + imm.
// ============================================================================
import riscv_pkg::*;

module decoderRTL #(
  parameter int WIDTH = 32
)(
  input  logic [WIDTH-1:0] instruction_i,
  output logic [6:0]       opcode_o,
  output logic [2:0]       funct3_o,
  output logic [6:0]       funct7_o,
  output logic [WIDTH-1:0] imm_o
);

  // ---- sabit-konum alan çıkarımı (her komutta aynı bitler) ----
  assign opcode_o = instruction_i[6:0];
  assign funct3_o = instruction_i[14:12];
  assign funct7_o = instruction_i[31:25];
  // (rs1=instruction_i[19:15], rs2=[24:20], rd=[11:7] de sabit — gerekince eklenir)

  // ---- opcode -> immediate format ----
  imm_sel_e imm_sel;
  always_comb begin
    unique case (instruction_i[6:0])
      OP_LOAD, OP_LOAD_FP,
      OP_OP_IMM, OP_JALR : imm_sel = IMM_I;
      OP_STORE, OP_STORE_FP : imm_sel = IMM_S;
      OP_BRANCH          : imm_sel = IMM_B;
      OP_LUI, OP_AUIPC   : imm_sel = IMM_U;
      OP_JAL             : imm_sel = IMM_J;
      // SYSTEM: CSR-immediate varyantları (CSRRWI/SI/CI) funct3[2]=1 -> zimm5
      OP_SYSTEM          : begin
                             if (instruction_i[14]) imm_sel = IMM_Z;
                             else                   imm_sel = IMM_I;
                           end
      default            : imm_sel = IMM_I;   // R-type: imm kullanılmaz
    endcase
  end

  // ---- immediate üretimi (bit karıştırması RISC-V formatına göre) ----
  always_comb begin
    unique case (imm_sel)
      IMM_I: imm_o = {{20{instruction_i[31]}}, instruction_i[31:20]};
      IMM_S: imm_o = {{20{instruction_i[31]}}, instruction_i[31:25], instruction_i[11:7]};
      IMM_B: imm_o = {{19{instruction_i[31]}}, instruction_i[31], instruction_i[7],
                       instruction_i[30:25], instruction_i[11:8], 1'b0};
      IMM_U: imm_o = {instruction_i[31:12], 12'b0};
      IMM_J: imm_o = {{11{instruction_i[31]}}, instruction_i[31], instruction_i[19:12],
                       instruction_i[20], instruction_i[30:21], 1'b0};
      IMM_Z: imm_o = {27'b0, instruction_i[19:15]};   // CSR zimm5
      default: imm_o = '0;
    endcase
  end

endmodule