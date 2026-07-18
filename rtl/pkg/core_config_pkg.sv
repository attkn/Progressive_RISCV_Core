// ============================================================================
//  core_config_pkg.sv  —  (1/5) İMPLEMENTASYON KARARLARI
//  Bu paket "biz ne yapmaya karar verdik"i tutar (ISA dayatmaz).
//  Bağımlılık: YOK (en alt katman)
// ============================================================================
package core_config_pkg;

  // --- veri yolu ---
  localparam int unsigned WIDTH      = 32;   // XLEN
  localparam int unsigned RS_ADDRESS = 5;    // register adres genişliği

  // --- bellek ---
  localparam int          IMEM_SIZE     = 4096;
  localparam              IMEM          = "imem.mem";
  localparam              DATA_MEM      = "memData.mem";
  localparam int          DATA_MEM_SIZE = 8192;

  // --- fonksiyonel birim boyutları ---
  localparam int ALU_OP_INT    = 20;   // 10 kullanılıyor, B uzantısı için yer var
  localparam int ALU_OP_MUL    = 4;    // MUL/MULH/MULHU/MULHSU
  localparam int ALU_OP_DIV    = 4;    // DIV/DIVU/REM/REMU
  localparam int ALU_OP_BRANCH = 7;    // 6 kullanılıyor (funct3-kodlu)
  localparam int MUL_LAT       = 3;    // çarpıcı pipeline derinliği

  // --- özellik anahtarları (aşamalı inşa) ---
  localparam bit M_EN = 1'b1;
  localparam bit A_EN = 1'b0;
  localparam bit C_EN = 1'b0;
  localparam bit B_EN = 1'b0;
  localparam bit F_EN = 1'b0;
  localparam bit V_EN = 1'b0;

  localparam logic [31:0] RESET_ADDR = 32'h0000_0000;

endpackage : core_config_pkg
