# ============================================================================
#  constraints/clk.xdc  —  M0 icin minimal zamanlama kisiti (sadece saat)
#  Pin yerlesimi YOK (board-a ozel, FPGA'ya indirirken eklenir).
#  200 MHz hedef; gercek fmax'i report_timing_summary'deki WNS gosterir.
# ============================================================================
create_clock -period 5.000 -name clk [get_ports clk_i]
