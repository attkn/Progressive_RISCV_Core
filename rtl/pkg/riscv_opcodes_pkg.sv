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

  // (funct7 sabitleri artık aşağıda 'funct7_e' enum'u olarak — tipli)

  // --- CSR adresleri (F için zorunlu) ---
  localparam logic [11:0] CSR_FFLAGS = 12'h001,   // F (K3)
                          CSR_FRM    = 12'h002,
                          CSR_FCSR   = 12'h003;
  // Faz 1 makine CSR'lari
  localparam logic [11:0]
    CSR_MISA      = 12'h301,
    CSR_MVENDORID = 12'hF11, CSR_MARCHID  = 12'hF12,
    CSR_MIMPID    = 12'hF13, CSR_MHARTID  = 12'hF14,
    CSR_MCYCLE    = 12'hB00, CSR_MCYCLEH  = 12'hB80,
    CSR_MINSTRET  = 12'hB02, CSR_MINSTRETH= 12'hB82,
    CSR_CYCLE     = 12'hC00, CSR_CYCLEH   = 12'hC80,
    CSR_INSTRET   = 12'hC02, CSR_INSTRETH = 12'hC82;
  // (trap CSR'lari: mstatus/mtvec/mepc/mcause/mie/mip -> K2)

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


  // ==========================================================================
  //  TİPLİ ALANLAR  —  control unit bunlarla case yazar (ham bit yerine isim)
  // ==========================================================================

  // --- opcode (tek anlamlı) ---
  typedef enum logic [6:0] {
    OPC_LOAD     = 7'b0000011, OPC_LOAD_FP  = 7'b0000111, OPC_MISC_MEM = 7'b0001111,
    OPC_OP_IMM   = 7'b0010011, OPC_AUIPC    = 7'b0010111,
    OPC_STORE    = 7'b0100011, OPC_STORE_FP = 7'b0100111, OPC_AMO      = 7'b0101111,
    OPC_OP       = 7'b0110011, OPC_LUI      = 7'b0110111,
    OPC_MADD     = 7'b1000011, OPC_MSUB     = 7'b1000111,
    OPC_NMSUB    = 7'b1001011, OPC_NMADD    = 7'b1001111, OPC_OP_FP = 7'b1010011,
    OPC_BRANCH   = 7'b1100011, OPC_JALR     = 7'b1100111, OPC_JAL   = 7'b1101111,
    OPC_SYSTEM   = 7'b1110011
  } opcode_e;

  // --- funct7 (tamsayı alanı: I/M/B). F ve A ayrı kodlanır (F: funct5+fmt, A: funct5) ---
  typedef enum logic [6:0] {
    F7_BASE        = 7'b0000000,  // ADD, SRL, SLT...
    F7_ALT         = 7'b0100000,  // SUB, SRA, ANDN, ORN, XNOR
    F7_MULDIV      = 7'b0000001,  // M uzantisi
    F7_SHADD       = 7'b0010000,  // Zba: sh1add/sh2add/sh3add
    F7_MINMAX_CLMUL= 7'b0000101,  // Zbb min/max + Zbc clmul
    F7_ZEXT        = 7'b0000100,  // Zbb zext.h
    F7_ROT_COUNT   = 7'b0110000,  // Zbb rol/ror/rori/clz/ctz/cpop/sext
    F7_BSET_ORC    = 7'b0010100,  // Zbs bset + Zbb orc.b
    F7_BCLR_BEXT   = 7'b0100100,  // Zbs bclr/bext
    F7_BINV_REV8   = 7'b0110100   // Zbs binv + Zbb rev8
  } funct7_e;

  // --- funct3: ANLAMI OPCODE'A GORE DEGISIR -> baglama ozel enum'lar ---
  // OP / OP_IMM  (temel ALU)
  typedef enum logic [2:0] {
    F3_ADD_SUB=3'b000, F3_SLL=3'b001, F3_SLT=3'b010, F3_SLTU=3'b011,
    F3_XOR=3'b100, F3_SR=3'b101, F3_OR=3'b110, F3_AND=3'b111
  } funct3_alu_e;

  // OP + F7_MULDIV  (M uzantisi)
  typedef enum logic [2:0] {
    F3_MUL=3'b000, F3_MULH=3'b001, F3_MULHSU=3'b010, F3_MULHU=3'b011,
    F3_DIV=3'b100, F3_DIVU=3'b101, F3_REM=3'b110, F3_REMU=3'b111
  } funct3_m_e;

  // LOAD / STORE  (erisim boyutu)
  typedef enum logic [2:0] {
    F3_B=3'b000, F3_H=3'b001, F3_W=3'b010, F3_BU=3'b100, F3_HU=3'b101
  } funct3_mem_e;

  // BRANCH  (kosul) — alu_op_branch_e ile ayni kodlama
  typedef enum logic [2:0] {
    F3_BEQ=3'b000, F3_BNE=3'b001, F3_BLT=3'b100,
    F3_BGE=3'b101, F3_BLTU=3'b110, F3_BGEU=3'b111
  } funct3_branch_e;

  // SYSTEM  (Zicsr + PRIV)
  typedef enum logic [2:0] {
    F3_PRIV=3'b000,                                   // ECALL/EBREAK/MRET
    F3_CSRRW=3'b001, F3_CSRRS=3'b010, F3_CSRRC=3'b011,
    F3_CSRRWI=3'b101, F3_CSRRSI=3'b110, F3_CSRRCI=3'b111
  } funct3_sys_e;

  // MISC-MEM
  typedef enum logic [2:0] { F3_FENCE=3'b000, F3_FENCE_I=3'b001 } funct3_fence_e;

endpackage : riscv_opcodes_pkg
