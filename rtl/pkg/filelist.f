// -----------------------------------------------------------------------------
// filelist.f  --  derleme sirasi burada tanimli. Tum araclara bunu ver.
//   verilator -f filelist.f ...
//   vcs      -f filelist.f
//   xrun     -f filelist.f
// -----------------------------------------------------------------------------

// 1) Paketler (SIRA ONEMLI: bagimliliklar once)
riscv_opcodes.sv
riscv_types.sv
riscv_pkg.sv

// 2) Moduller
aluInt.sv
immGen.sv
controlUnit.sv
