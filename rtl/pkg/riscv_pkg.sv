// ============================================================================
//  riscv_pkg.sv  —  ÜST PAKET (tek giriş noktası)
// ----------------------------------------------------------------------------
//  Alt paketleri toplar ve yeniden ihraç eder; modüller yalnızca
//      import riscv_pkg::*;
//  yazar. Derleme sırası (flist/rtl.f'te bu sırayla):
//      core_config_pkg -> riscv_opcodes_pkg -> riscv_ctrl_pkg
//      -> riscv_types_pkg -> riscv_isa_id_pkg -> riscv_pkg
//
//  ARAÇ NOTU: 'export pkg::*' IEEE 1800 standardıdır ve ticari araçlarda
//  (Vivado / Questa / VCS / Xcelium) çalışır. Icarus Verilog DESTEKLEMEZ.
//  Icarus ile derlerken -DNO_PKG_EXPORT verin ve modüllerde
//  `include "riscv_imports.svh" kullanın (aynı etkiyi taşınabilir şekilde verir).
// ============================================================================
package riscv_pkg;
  import core_config_pkg::*;
  import riscv_opcodes_pkg::*;
  import riscv_ctrl_pkg::*;
  import riscv_types_pkg::*;
  import riscv_isa_id_pkg::*;

`ifndef NO_PKG_EXPORT
  export core_config_pkg::*;
  export riscv_opcodes_pkg::*;
  export riscv_ctrl_pkg::*;
  export riscv_types_pkg::*;
  export riscv_isa_id_pkg::*;
`endif

  // üst seviye kısayollar
  localparam string CORE_NAME = "rv32imacbfv";

endpackage : riscv_pkg
