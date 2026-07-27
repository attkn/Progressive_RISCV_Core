# ============================================================================
#  scripts/vivado_sim.tcl
#  KV260 projesini kurar ve M0 cekirdegini xsim'de (davranissal) simule eder.
#  Calistirma (repo kokunden):
#     vivado -mode batch -source scripts/vivado_sim.tcl
#  GUI'de acmak istersen sonrasinda:  build/vivado/riscv_core.xpr
# ============================================================================

set PART     xck26-sfvc784-2LV-c        ;# Kria KV260 / K26 SOM
set PROJ     riscv_core
set PROJ_DIR build/vivado

# ---- 1) imem.mem uret (test programi) ----
puts "== imem.mem uretiliyor =="
exec python3 sw/asm.py
set MEMFILE [file normalize sw/imem.mem]

# ---- 2) proje (temiz kur) ----
create_project -force $PROJ $PROJ_DIR -part $PART

# ---- 3) tasarim kaynaklari: paketler (DERLEME SIRASI) + RTL ----
add_files -norecurse [list \
  rtl/pkg/core_config_pkg.sv \
  rtl/pkg/riscv_opcodes_pkg.sv \
  rtl/pkg/riscv_ctrl_pkg.sv \
  rtl/pkg/riscv_types_pkg.sv \
  rtl/pkg/riscv_isa_id_pkg.sv \
  rtl/pkg/riscv_pkg.sv \
  rtl/leaf_pc.sv rtl/leaf_regfile.sv rtl/leaf_imem.sv rtl/leaf_dmem.sv \
  rtl/decoder.sv rtl/control.sv rtl/aluInt.sv rtl/aluBranch.sv rtl/csrFile.sv \
  rtl/coreM0RTL.sv \
]

# ---- 4) testbench (yalnizca simulasyon) ----
add_files -fileset sim_1 -norecurse [list tb/tb_m0.sv]

# ---- 5) include dizini (riscv_imports.svh icin) ----
set_property include_dirs [file normalize rtl/pkg] [get_filesets sources_1]
set_property include_dirs [file normalize rtl/pkg] [get_filesets sim_1]

# ---- 6) mem dosyasi yolunu sim'e define olarak ver ----
#   $readmemh xsim-dizini yerine bu mutlak yolu okur (calisma-dizini derdi biter).
#   DIKKAT: NO_PKG_EXPORT TANIMLAMIYORUZ -> Vivado 'export'u destekler,
#           dolayisiyla 'import riscv_pkg::*;' kullanan modullerin de calisir.
set_property verilog_define "IMEM_FILE=\"$MEMFILE\"" [get_filesets sim_1]

# ---- 7) top moduller ----
set_property top coreM0RTL [get_filesets sources_1]
set_property top tb_m0     [get_filesets sim_1]
update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

# ---- 8) davranissal simulasyon ----
puts "== xsim baslatiliyor =="
launch_simulation
run all
puts "== SIM BITTI: yukaridaki \$display ciktisinda '7 tests, 0 errors / ALL PASS' bekleniyor =="

# ---------------------------------------------------------------------------
#  imem.mem hala bulunamazsa (define tirnak sorunu nadiren cikar), yedek:
#  launch_simulation -scripts_only ile dizini olustur, sonra:
#    file copy -force sw/imem.mem \
#      build/vivado/riscv_core.sim/sim_1/behav/xsim/imem.mem
#  ve leaf_imem'deki varsayilan "imem.mem" yolu bunu bulur.
# ---------------------------------------------------------------------------
