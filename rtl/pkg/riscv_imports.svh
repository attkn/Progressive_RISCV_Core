// ============================================================================
//  riscv_imports.svh  —  taşınabilir "hepsini içeri al" başlığı
//  Kullanım (modül dosyasının EN ÜSTÜNDE):
//      `include "riscv_imports.svh"
//      module foo ( ... );
//  Aracınız 'export' destekliyorsa bunun yerine  import riscv_pkg::*;  yeter.
// ============================================================================
import core_config_pkg::*;
import riscv_opcodes_pkg::*;
import riscv_ctrl_pkg::*;
import riscv_types_pkg::*;
import riscv_isa_id_pkg::*;
