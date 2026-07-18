// ============================================================================
//  riscv_isa_id_pkg.sv  —  (5/5) ISA KİMLİK ENUM'LARI  [opsiyonel]
//  "Hangi komut" listeleri: dokümantasyon / trace / debug.
//  RTL zorunlu DEĞİL (decoder doğrudan ctrl_t üretir).
//  Üye önekleri (I_ CSR_ M_ A_ C_ B_ F_) kontrol enum'larıyla çakışmayı önler.
//  Bağımlılık: riscv_opcodes_pkg (komut sayıları)
// ============================================================================
package riscv_isa_id_pkg;
  import riscv_opcodes_pkg::*;

  typedef enum logic [$clog2(ISA_I)-1:0] {
    I_LUI, I_AUIPC, I_JAL, I_JALR,
    I_BEQ, I_BNE, I_BLT, I_BGE, I_BLTU, I_BGEU,
    I_LB, I_LH, I_LW, I_LBU, I_LHU,
    I_SB, I_SH, I_SW,
    I_ADDI, I_SLTI, I_SLTIU, I_XORI, I_ORI, I_ANDI,
    I_SLLI, I_SRLI, I_SRAI,
    I_ADD, I_SUB, I_SLL, I_SLT, I_SLTU, I_XOR, I_SRL, I_SRA, I_OR, I_AND,
    I_FENCE, I_ECALL, I_EBREAK
  } isa_i_e;                                            // 40

  typedef enum logic [$clog2(ISA_CSR+ISA_FENCE)-1:0] {
    CSR_CSRRW, CSR_CSRRS, CSR_CSRRC,
    CSR_CSRRWI, CSR_CSRRSI, CSR_CSRRCI,
    CSR_FENCE_I
  } isa_csr_e;                                          // 6 + 1

  typedef enum logic [$clog2(ISA_M)-1:0] {
    M_MUL, M_MULH, M_MULHSU, M_MULHU,
    M_DIV, M_DIVU, M_REM, M_REMU
  } isa_m_e;                                            // 8

  typedef enum logic [$clog2(ISA_A)-1:0] {
    A_LR_W, A_SC_W,
    A_AMOSWAP_W, A_AMOADD_W, A_AMOXOR_W, A_AMOAND_W, A_AMOOR_W,
    A_AMOMIN_W, A_AMOMAX_W, A_AMOMINU_W, A_AMOMAXU_W
  } isa_a_e;                                            // 11

  typedef enum logic [$clog2(ISA_C)-1:0] {
    C_ADDI4SPN, C_LW, C_SW, C_FLW, C_FSW,
    C_NOP_ADDI, C_JAL, C_LI, C_LUI_ADDI16SP,
    C_SRLI, C_SRAI, C_ANDI, C_SUB, C_XOR, C_OR, C_AND,
    C_J, C_BEQZ, C_BNEZ,
    C_SLLI, C_LWSP, C_FLWSP,
    C_JR, C_MV, C_EBREAK, C_JALR, C_ADD,
    C_SWSP, C_FSWSP
  } isa_c_e;                                            // 29

  typedef enum logic [$clog2(ISA_B)-1:0] {
    B_SH1ADD, B_SH2ADD, B_SH3ADD,                              // Zba
    B_ANDN, B_ORN, B_XNOR, B_CLZ, B_CTZ, B_CPOP,               // Zbb
    B_MAX, B_MAXU, B_MIN, B_MINU,
    B_SEXT_B, B_SEXT_H, B_ZEXT_H,
    B_ROL, B_ROR, B_RORI, B_ORC_B, B_REV8,
    B_BCLR, B_BCLRI, B_BEXT, B_BEXTI,                          // Zbs
    B_BINV, B_BINVI, B_BSET, B_BSETI,
    B_CLMUL, B_CLMULH, B_CLMULR                                // Zbc
  } isa_b_e;                                            // 32

  typedef enum logic [$clog2(ISA_F)-1:0] {
    F_FLW, F_FSW,
    F_FMADD_S, F_FMSUB_S, F_FNMSUB_S, F_FNMADD_S,
    F_FADD_S, F_FSUB_S, F_FMUL_S, F_FDIV_S, F_FSQRT_S,
    F_FSGNJ_S, F_FSGNJN_S, F_FSGNJX_S,
    F_FMIN_S, F_FMAX_S,
    F_FCVT_W_S, F_FCVT_WU_S, F_FMV_X_W,
    F_FEQ_S, F_FLT_S, F_FLE_S, F_FCLASS_S,
    F_FCVT_S_W, F_FCVT_S_WU, F_FMV_W_X
  } isa_f_e;                                            // 26

endpackage : riscv_isa_id_pkg
