// ============================================================================
//  decoderRTL : komut -> TIPLI ALANLAR (instr_fields_t)
// ----------------------------------------------------------------------------
//  Amac: control unit'in isini kolaylastirmak. Ham bit dilimleme ve immediate
//  karistirmasi BURADA biter; control unit sadece  case (f.opcode)  yazar.
//
//  Tasarim notu: funct3 HAM birakildi — anlami opcode'a gore degisir
//  (010 = LOAD'da word, OP'ta SLT, SYSTEM'de CSRRS). Control unit baglama
//  gore cast eder:   unique case (funct3_alu_e'(f.funct3))
//  opcode ve funct7 tek anlamli oldugu icin TIPLI cikar.
// ============================================================================
`include "riscv_imports.svh"

module decoderRTL #(
  parameter int W = WIDTH
)(
  input  logic [W-1:0]  instruction_i,
  output instr_fields_t fields_o
);

  logic [6:0]    raw_opcode;
  imm_sel_e      imm_sel;
  instr_fields_t f;                       // ic degisken (port'a tek atama)

  assign raw_opcode = instruction_i[6:0];
  assign fields_o   = f;

  // ---- opcode -> immediate formati ----
  always_comb begin
    unique case (raw_opcode)
      OPC_LOAD, OPC_LOAD_FP, OPC_OP_IMM, OPC_JALR : imm_sel = IMM_I;
      OPC_STORE, OPC_STORE_FP                     : imm_sel = IMM_S;
      OPC_BRANCH                                  : imm_sel = IMM_B;
      OPC_LUI, OPC_AUIPC                          : imm_sel = IMM_U;
      OPC_JAL                                     : imm_sel = IMM_J;
      OPC_SYSTEM: begin                             // CSRRWI/SI/CI -> zimm5
                    if (instruction_i[14]) imm_sel = IMM_Z;
                    else                   imm_sel = IMM_I;
                  end
      default                                     : imm_sel = IMM_I;
    endcase
  end

  always_comb begin
    // ---- sabit-konum alanlar (her komutta ayni bitler) ----
    f.opcode   = opcode_e'(raw_opcode);
    f.funct3   = instruction_i[14:12];
    f.funct7   = funct7_e'(instruction_i[31:25]);
    f.rs1      = instruction_i[19:15];
    f.rs2      = instruction_i[24:20];
    f.rd       = instruction_i[11:7];
    f.shamt    = instruction_i[24:20];
    f.csr_addr = instruction_i[31:20];

    // ---- opcode taniniyor mu (illegal tespitinin ilk adimi) ----
    unique case (raw_opcode)
      OPC_LOAD, OPC_LOAD_FP, OPC_MISC_MEM, OPC_OP_IMM, OPC_AUIPC,
      OPC_STORE, OPC_STORE_FP, OPC_AMO, OPC_OP, OPC_LUI,
      OPC_MADD, OPC_MSUB, OPC_NMSUB, OPC_NMADD, OPC_OP_FP,
      OPC_BRANCH, OPC_JALR, OPC_JAL, OPC_SYSTEM: f.opcode_valid = 1'b1;
      default:                                   f.opcode_valid = 1'b0;
    endcase

    // ---- immediate uretimi ----
    unique case (imm_sel)
      IMM_I: f.imm = {{20{instruction_i[31]}}, instruction_i[31:20]};
      IMM_S: f.imm = {{20{instruction_i[31]}}, instruction_i[31:25], instruction_i[11:7]};
      IMM_B: f.imm = {{19{instruction_i[31]}}, instruction_i[31], instruction_i[7],
                       instruction_i[30:25], instruction_i[11:8], 1'b0};
      IMM_U: f.imm = {instruction_i[31:12], 12'b0};
      IMM_J: f.imm = {{11{instruction_i[31]}}, instruction_i[31], instruction_i[19:12],
                       instruction_i[20], instruction_i[30:21], 1'b0};
      IMM_Z: f.imm = {27'b0, instruction_i[19:15]};
      default: f.imm = '0;
    endcase
  end

endmodule
