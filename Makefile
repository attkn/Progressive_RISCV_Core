# ============================================================================
#  RV32IMACBFV — build/test Makefile   (repo koku)
#  Hedefler:  make lint | sim | cosim | formal | all | clean
#  Not: dosya adlarindan "RTL" dusuruldu (senin repo'na gore); yollar rtl/ +
#       rtl/pkg/. Kendi leaf modullerini kullanmak istersen asagidaki LEAF
#       secimini degistir (aciklama var).
# ============================================================================
IVERILOG ?= iverilog
VVP      ?= vvp
VERILATOR?= verilator
PY       ?= python3

# ---- dizinler ----
RTL   := rtl
PKGD  := rtl/pkg
TB    := tb
SW    := sw
VERIF := verif
BUILD := build

# -I ile paket dizini (riscv_imports.svh icin) + Icarus'a export yok
IFLAGS := -g2012 -DNO_PKG_EXPORT -I$(PKGD)
TOP    ?= coreM0RTL

# ---- paketler (DERLEME SIRASI onemli: bagimlilik zinciri) ----
PKG := \
  $(PKGD)/core_config_pkg.sv \
  $(PKGD)/riscv_opcodes_pkg.sv \
  $(PKGD)/riscv_ctrl_pkg.sv \
  $(PKGD)/riscv_types_pkg.sv \
  $(PKGD)/riscv_isa_id_pkg.sv \
  $(PKGD)/riscv_pkg.sv

# ---- LEAF modulleri (M0 datapath) ----
#  (A) benim dogrulanmis leaf_*'larim — coreM0RTL bunlarin MODUL adlarini
#      instantiate ediyor (pcRTL/regFileRTL/instrMemRTL/dataMemRTL):
LEAF := $(RTL)/leaf_pc.sv $(RTL)/leaf_regfile.sv $(RTL)/leaf_imem.sv $(RTL)/leaf_dmem.sv
#  (B) kendi modullerin (pc/gpr/instructionMemory/dataMemory) — kullanmak icin
#      yukaridaki satiri yorumla, asagidakini ac VE coreM0RTL icindeki
#      instantiation'lari senin modul adlarina/portlarina gore guncelle:
# LEAF := $(RTL)/pc.sv $(RTL)/gpr.sv $(RTL)/instructionMemory.sv $(RTL)/dataMemory.sv

# ---- M0 cekirdek RTL'i (RTL-siz dosya adlari, MODUL adlari degismedi) ----
RTL_M0 := \
  $(LEAF) \
  $(RTL)/decoder.sv \
  $(RTL)/control.sv \
  $(RTL)/aluInt.sv \
  $(RTL)/aluBranch.sv \
  $(RTL)/csrFile.sv \
  $(RTL)/coreM0RTL.sv

# (M/C/B/F, M2 ve OoO modulleri M0 build'inde YOK — sirasi gelince eklenecek:
#  multiplier.sv divider.sv aluTop.sv fpr.sv immGenerator.sv pcAdder.sv
#  hazard.sv forwarding.sv pipelineRegs.sv pipeReg.sv)

SRCS := $(PKG) $(RTL_M0)

.PHONY: all sim cosim lint formal clean
all: lint cosim

# imem.mem uret (sw/ icinde)
$(SW)/imem.mem: $(SW)/asm.py
	cd $(SW) && $(PY) asm.py

# 1) self-checking entegrasyon sim (M0)
sim: $(SW)/imem.mem
	@mkdir -p $(BUILD)
	$(IVERILOG) $(IFLAGS) -o $(BUILD)/sm0 $(SRCS) $(TB)/tb_m0.sv
	cd $(SW) && $(VVP) $(abspath $(BUILD))/sm0

# 2) golden-model (Spike) lockstep co-sim
cosim: $(SW)/imem.mem
	@mkdir -p $(BUILD)
	$(IVERILOG) $(IFLAGS) -o $(BUILD)/scos $(SRCS) $(TB)/tb_cosim.sv
	cd $(SW) && $(VVP) $(abspath $(BUILD))/scos
	$(PY) $(VERIF)/iss.py  $(SW)/imem.mem 40 $(BUILD)/golden_trace.log
	cp $(SW)/rtl_trace.log $(BUILD)/rtl_trace.log
	$(PY) $(VERIF)/cosim.py $(BUILD)/rtl_trace.log $(BUILD)/golden_trace.log

# 3) Verilator lint (gerekcelendirilmis waiver'larla TERTEMIZ)
lint:
	$(VERILATOR) --lint-only -Wall -Wno-DECLFILENAME -Wno-UNUSEDPARAM \
	  -I$(PKGD) -DNO_PKG_EXPORT --top-module $(TOP) $(VERIF)/waivers.vlt $(SRCS)

# 4) SymbiYosys formal (yosys + sby gerektirir)
formal:
	sby -f formal/alu_int.sby

clean:
	rm -rf $(BUILD) $(SW)/imem.mem $(SW)/*.log *.log obj_dir

# ============================================================================
#  VIVADO hedefleri (KV260)  —  xsim sim + OOC sentez
# ----------------------------------------------------------------------------
#  Vivado PATH'te degilse settings64.sh source'lanir. Kendi kurulumuna gore:
#    make vsim VIVADO_SETTINGS=/tools/Xilinx/Vivado/2024.1/settings64.sh
#  Zaten PATH'teyse VIVADO_SETTINGS'i bos birak (source atlanir).
#  import riscv_pkg::*; Vivado'da calisir (export destekli) -> NO_PKG_EXPORT YOK.
# ============================================================================
VIVADO ?= vivado

# settings64.sh yolu — yaygin konumlari otomatik dene, yoksa bos
VIVADO_SETTINGS ?= $(firstword $(wildcard \
  /tools/Xilinx/Vivado/*/settings64.sh \
  /opt/Xilinx/Vivado/*/settings64.sh \
  $(HOME)/Xilinx/Vivado/*/settings64.sh))

# source varsa "source X &&", yoksa bos -> tek satirda subshell icinde
VSRC = $(if $(VIVADO_SETTINGS),. $(VIVADO_SETTINGS) &&,)

.PHONY: vsim vsynth vgui vclean vcheck

# Vivado gorunuyor mu? (source dahil)
vcheck:
	@echo "VIVADO_SETTINGS = $(VIVADO_SETTINGS)"
	$(VSRC) which $(VIVADO) && $(VSRC) $(VIVADO) -version | head -1

# tek komut: proje kur + xsim davranissal sim
vsim: $(SW)/imem.mem
	@mkdir -p build
	$(VSRC) $(VIVADO) -mode batch -source scripts/vivado_sim.tcl -notrace -log build/vivado_sim.log -journal build/vivado_sim.jou
	@echo ">>> sim bitti — sonuc: build/vivado_sim.log (7 tests, 0 errors bekleniyor)"

# OOC sentez + kaynak/timing raporu
vsynth:
	@mkdir -p build
	$(VSRC) $(VIVADO) -mode batch -source scripts/vivado_synth.tcl -notrace -log build/vivado_synth.log -journal build/vivado_synth.jou
	@echo ">>> util.rpt ve timing.rpt -> build/vivado/"

# projeyi GUI'de ac
vgui:
	$(VSRC) $(VIVADO) build/vivado/riscv_core.xpr &

vclean:
	rm -rf build/vivado *.jou *.log vivado*.jou vivado*.log .Xil
