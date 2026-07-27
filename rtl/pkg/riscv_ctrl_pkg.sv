// ============================================================================
//  riscv_ctrl_pkg.sv  —  (3/5) YAPRAK KONTROL ENUM'LARI
//  Fonksiyonel birimleri SÜREN sinyal tipleri.
//  Bağımlılık: core_config_pkg (boyut parametreleri)
// ============================================================================
package riscv_ctrl_pkg;
  import core_config_pkg::*;

  // immediate format seçimi
  typedef enum logic [2:0] {
    IMM_I, IMM_S, IMM_B, IMM_U, IMM_J, IMM_Z
  } imm_sel_e;

  // tamsayı ALU (aluIntRTL)
  typedef enum logic [$clog2(ALU_OP_INT)-1:0] {
    ALU_ADD, ALU_SUB, ALU_AND, ALU_OR,  ALU_XOR,
    ALU_SLL, ALU_SRL, ALU_SRA, ALU_SLT, ALU_SLTU
  } alu_op_int_e;

  // branch koşulu (aluBranchRTL) — değerler = funct3
  typedef enum logic [$clog2(ALU_OP_BRANCH)-1:0] {
    BR_EQ  = 3'b000, BR_NE  = 3'b001, BR_LT  = 3'b100,
    BR_GE  = 3'b101, BR_LTU = 3'b110, BR_GEU = 3'b111
  } alu_op_branch_e;
  typedef alu_op_branch_e branch_op_e;   // alias (mevcut modüller kullanıyor)

  // çarpma modu (multiplierRTL)
  typedef enum logic [$clog2(ALU_OP_MUL)-1:0] {
    MUL, MULH, MULHU, MULHSU
  } alu_op_mul_e;

  // bölme modu (div_r4)
  typedef enum logic [$clog2(ALU_OP_DIV)-1:0] {
    DIV, DIVU, REM, REMU
  } alu_op_div_e;

  // hangi fonksiyonel birim
  typedef enum logic [2:0] {
    UNIT_INT, UNIT_BRANCH, UNIT_MUL, UNIT_DIV, UNIT_MEM, UNIT_CSR, UNIT_FPU
  } unit_sel_e;

  // ALU operand kaynakları
  typedef enum logic [1:0] { OPA_RS1, OPA_PC, OPA_ZERO } op_a_sel_e;
  typedef enum logic [1:0] { OPB_RS2, OPB_IMM         } op_b_sel_e;

  // writeback kaynağı
  typedef enum logic [1:0] { WB_ALU, WB_MEM, WB_PC4, WB_CSR } wb_sel_e;

  // forwarding kaynağı (bypass ağı)
  typedef enum logic [1:0] {
    FWD_NONE,     // register file'dan oku (bypass yok)
    FWD_EX_MEM,   // EX/MEM'den ilet (en taze deger — ONCELIKLI)
    FWD_MEM_WB    // MEM/WB'den ilet
  } fwd_sel_e;

  // CSR işlemi (Zicsr)
  typedef enum logic [1:0] { CSR_OP_NONE, CSR_OP_RW, CSR_OP_RS, CSR_OP_RC } csr_op_e;

endpackage : riscv_ctrl_pkg
