# Progressive RISC-V Core — M0 dogrulanmis temel (RV32I + Zicsr, single-cycle)

Bu paket, UCTAN UCA DOGRULANMIS M0 cekirdegin tam ve tutarli hâlidir.
Amac: repo'daki eski/uyumsuz RTL dosyalarini (orn. aluInt.sv'de artik
kullanilmayan `alu_mode_int_e`/`alu_op_e` tipleri) guncel setle degistirmek.

## Ne yapmali
1. Bu arsivi repo KOKUNE ac (mevcut dosyalarin uzerine yazar).
2. Test et:
     make sim      # iverilog  -> 7 tests, 0 errors bekleniyor
     make vsim     # Vivado/xsim (KV260)  -> ayni sonuc
     make cosim    # golden-model lockstep (iverilog + python)
     make lint     # verilator (waiver'li, temiz)

## Onemli: import mekanizmasi
Tum moduller  `include "riscv_imports.svh"  kullanir (import riscv_pkg::*; DEGIL).
Sebep: iverilog paket `export`'unu desteklemiyor; include HER iki araçta calisir
(iverilog: -Irtl/pkg -DNO_PKG_EXPORT ; Vivado: include_dirs=rtl/pkg).
Eski dosyalarinda `import riscv_pkg::*;` varsa bu set onlari degistirir.

## Bu arsivde OLMAYAN (senin kendi modullerin — DOKUNULMADI)
gpr.sv, pc.sv, instructionMemory.sv, dataMemory.sv, immGenerator.sv,
pcAdder.sv, fpr.sv, divider.sv, multiplier.sv, aluTop.sv
-> Bunlar repo'nda kalir. M0 su an benim leaf_* modullerimi kullaniyor.
   Kendi modullerini baglamak icin coreM0RTL icindeki instantiation'lari
   ve Makefile'daki LEAF degiskenini guncelleriz (port arayuzlerin gerekli).

## Dizin yapisi
  rtl/pkg/    paketler (+ riscv_imports.svh, rtl_pkg.f)
  rtl/        RTL modulleri (M0) + leaf_*
  tb/         testbench'ler
  sw/         asm.py (imem.mem ureteci)
  verif/      iss.py, cosim.py, waivers.vlt
  scripts/    vivado_sim.tcl, vivado_synth.tcl
  constraints/clk.xdc
  ci/         ci.yml  (-> .github/workflows/ci.yml'e koy)
  Makefile
