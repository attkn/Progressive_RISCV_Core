// ============================================================================
//  riscv_types_pkg.sv  —  (4/5) KONTROL DEMETLERİ + PIPELINE TİPLERİ
//  Decoder ctrl_t üretir; her aşama payını tüketir, kalanı taşır.
//  Bağımlılık: core_config_pkg (WIDTH/RS_ADDRESS) + riscv_ctrl_pkg (enum'lar)
// ============================================================================
package riscv_types_pkg;
  import core_config_pkg::*;
  import riscv_opcodes_pkg::*;
  import riscv_ctrl_pkg::*;

  // ==========================================================================
  //  DECODER CIKTISI — TIPLI ALANLAR
  //  Control unit bunu alir ve  case (f.opcode)  ile calisir (ham bit yok).
  //  funct3 HAM birakilir cunku anlami opcode'a gore degisir; control unit
  //  baglama gore cast eder:  funct3_alu_e'(f.funct3) / funct3_mem_e'(f.funct3)
  // ==========================================================================
  typedef struct packed {
    opcode_e               opcode;        // TIPLI
    logic [2:0]            funct3;        // ham (baglama gore cast edilir)
    funct7_e               funct7;        // TIPLI
    logic [RS_ADDRESS-1:0] rs1;
    logic [RS_ADDRESS-1:0] rs2;
    logic [RS_ADDRESS-1:0] rd;
    logic [WIDTH-1:0]      imm;
    logic [4:0]            shamt;         // I-type shift: inst[24:20]
    logic [11:0]           csr_addr;      // Zicsr: inst[31:20]
    logic                  opcode_valid;  // taninan opcode mu
  } instr_fields_t;

  // ---------------- kontrol demetleri ----------------
  typedef struct packed {                 // EX aşaması
    alu_op_int_e    alu_op;
    alu_op_branch_e br_op;
    alu_op_mul_e    mul_op;
    alu_op_div_e    div_op;
    unit_sel_e      unit_sel;
    op_a_sel_e      op_a_sel;
    op_b_sel_e      op_b_sel;
    logic           is_branch;
    logic           is_jump;
    csr_op_e        csr_op;
    logic           csr_use_imm;
  } ctrl_ex_t;

  typedef struct packed {                 // MEM aşaması
    logic       mem_read;
    logic       mem_write;
    logic [2:0] mem_size;                 // funct3
  } ctrl_mem_t;

  typedef struct packed {                 // WB aşaması
    logic    reg_write;
    wb_sel_e wb_sel;
  } ctrl_wb_t;

  typedef struct packed {                 // decoder çıkışı (tam demet)
    ctrl_ex_t  ex;
    ctrl_mem_t mem;
    ctrl_wb_t  wb;
    logic      illegal;
  } ctrl_t;

  // ---------------- pipeline register tipleri ----------------
  // Demet aşama aşama KÜÇÜLÜR. Bubble/flush: '<= '0'.
  typedef struct packed {                          // IF/ID
    logic [WIDTH-1:0] pc;
    logic [WIDTH-1:0] instr;
    logic             valid;
  } if_id_t;

  typedef struct packed {                          // ID/EX
    ctrl_t                 ctrl;
    logic [WIDTH-1:0]      pc;
    logic [WIDTH-1:0]      imm;
    logic [WIDTH-1:0]      rs1_val;
    logic [WIDTH-1:0]      rs2_val;
    logic [RS_ADDRESS-1:0] rs1_addr;               // forwarding/hazard
    logic [RS_ADDRESS-1:0] rs2_addr;
    logic [RS_ADDRESS-1:0] rd_addr;
    logic                  valid;
  } id_ex_t;

  typedef struct packed {                          // EX/MEM (ex tüketildi)
    ctrl_mem_t             mem;
    ctrl_wb_t              wb;
    logic [WIDTH-1:0]      alu_result;
    logic [WIDTH-1:0]      rs2_val;                // store verisi
    logic [WIDTH-1:0]      pc_plus4;
    logic [RS_ADDRESS-1:0] rd_addr;
    logic                  valid;
  } ex_mem_t;

  typedef struct packed {                          // MEM/WB (sadece wb)
    ctrl_wb_t              wb;
    logic [WIDTH-1:0]      wb_data;
    logic [RS_ADDRESS-1:0] rd_addr;
    logic                  valid;
  } mem_wb_t;

endpackage : riscv_types_pkg
