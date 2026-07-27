# ============================================================================
#  scripts/vivado_synth.tcl
#  Hizli OOC (out-of-context) sentez + kaynak/timing raporu (KV260 part).
#  "Ne kadar buyuk / ne kadar hizli" sorusuna cevap. FPGA'ya indirmek DEGIL.
#  Calistirma (repo kokunden):
#     vivado -mode batch -source scripts/vivado_synth.tcl
#  Ciktilar: build/vivado/util.rpt , build/vivado/timing.rpt
# ============================================================================
set PART xck26-sfvc784-2LV-c
file mkdir build/vivado

read_verilog -sv [list \
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

# OOC: sadece cekirdegi sentezle (I/O buffer ekleme; cekirdekte gercek I/O yok)
synth_design -top coreM0RTL -part $PART -mode out_of_context \
             -include_dirs [file normalize rtl/pkg]

# kaynak raporu (kac LUT / FF / DSP / BRAM)
report_utilization -file build/vivado/util.rpt
puts "== KAYNAK: build/vivado/util.rpt =="

# timing icin saat tanimi (5 ns = 200 MHz hedef; kendine gore ayarla)
create_clock -period 5.000 -name clk [get_ports clk_i]
report_timing_summary -delay_type max -file build/vivado/timing.rpt
puts "== TIMING: build/vivado/timing.rpt (WNS pozitifse hedef karsilaniyor) =="
