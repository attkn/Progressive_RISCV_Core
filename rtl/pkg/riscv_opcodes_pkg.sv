// ============================================================================
//  riscv_opcodes_pkg.sv  —  (2/5) ISA'NIN DAYATTIKLARI
//  Spec tarafından sabitlenmiş: opcode/funct alanları + komut sayıları.
//  Bağımlılık: YOK
// ============================================================================
package riscv_opcodes_pkg;

  // --- opcode  (inst[6:0] — konum her komutta sabit) ---
  localparam logic [6:0]
    OP_LOAD     = 7'b0000011, OP_LOAD_FP  = 7'b0000111, OP_MISC_MEM = 7'b0001111,
    OP_OP_IMM   = 7'b0010011, OP_AUIPC    = 7'b0010111,
    OP_STORE    = 7'b0100011, OP_STORE_FP = 7'b0100111, OP_AMO      = 7'b0101111,
    OP_OP       = 7'b0110011, OP_LUI      = 7'b0110111,
    OP_MADD     = 7'b1000011, OP_MSUB     = 7'b1000111,
    OP_NMSUB    = 7'b1001011, OP_NMADD    = 7'b1001111, OP_OP_FP    = 7'b1010011,
    OP_BRANCH   = 7'b1100011, OP_JALR     = 7'b1100111, OP_JAL      = 7'b1101111,
    OP_SYSTEM   = 7'b1110011;

  // --- ayırt edici funct7 (inst[31:25]) ---
  localparam logic [6:0] F7_BASE = 7'b0000000,   // ADD, SRL...
                         F7_ALT  = 7'b0100000,   // SUB, SRA
                         F7_MUL  = 7'b0000001;   // M uzantısı

  // --- CSR adresleri (F için zorunlu) ---
  localparam logic [11:0] CSR_FFLAGS = 12'h001,
                          CSR_FRM    = 12'h002,
                          CSR_FCSR   = 12'h003;

  // --- komut sayıları ---
  localparam int ISA_I     = 40;   // RV32I
  localparam int ISA_M     = 8;    // çarpma/bölme
  localparam int ISA_CSR   = 6;    // Zicsr
  localparam int ISA_FENCE = 1;    // Zifencei
  localparam int ISA_A     = 11;   // RV32A
  localparam int ISA_C     = 29;   // RV32C (+Zcf)
  localparam int ISA_B     = 32;   // Zba+Zbb+Zbs (29) + Zbc (3)
  localparam int ISA_F     = 26;   // RV32F
  localparam int ISA_TOTAL = ISA_I + ISA_M + ISA_CSR + ISA_FENCE
                           + ISA_A + ISA_C + ISA_B + ISA_F;   // = 153

endpackage : riscv_opcodes_pkg
