// ============================================================================
//  pipelineRegsRTL : 5-stage pipeline register'lari (IF/ID, ID/EX, EX/MEM, MEM/WB)
// ----------------------------------------------------------------------------
//  hazardRTL'in urettigi stall/flush sinyalleri buraya baglanir:
//
//    hazard ciktisi        -> hangi register
//    ------------------------------------------------
//    if_id_stall/flush     -> IF/ID
//    id_ex_flush           -> ID/EX  (balon)
//    ex_mem_flush          -> EX/MEM (cok-cycle balonu)
//    (pc_stall)            -> PC (bu modulun disinda, fetch tarafinda)
//
//  ID/EX stall'i ayri porttan gelir: cok-cycle birim calisirken EX'teki komut
//  DONDURULUR (flush degil) — hazard unit'te id_ex_flush=0, busy=1 durumu.
// ============================================================================
`include "riscv_imports.svh"

module pipelineRegsRTL (
  input  logic clk_i,
  input  logic rst_ni,

  // ---- hazard/kontrol ----
  input  logic if_id_stall_i,
  input  logic if_id_flush_i,
  input  logic id_ex_stall_i,     // cok-cycle birim mesgul -> EX'i dondur
  input  logic id_ex_flush_i,
  input  logic ex_mem_flush_i,

  // ---- asama girisleri (kombinasyonel mantiktan) ----
  input  if_id_t  if_id_d_i,
  input  id_ex_t  id_ex_d_i,
  input  ex_mem_t ex_mem_d_i,
  input  mem_wb_t mem_wb_d_i,

  // ---- asama ciktilari (bir sonraki asamaya) ----
  output if_id_t  if_id_q_o,
  output id_ex_t  id_ex_q_o,
  output ex_mem_t ex_mem_q_o,
  output mem_wb_t mem_wb_q_o
);

  // IF/ID : fetch -> decode
  pipeRegRTL #(.T(if_id_t)) u_if_id (
    .clk_i(clk_i), .rst_ni(rst_ni),
    .flush_i(if_id_flush_i), .stall_i(if_id_stall_i),
    .d_i(if_id_d_i), .q_o(if_id_q_o)
  );

  // ID/EX : decode -> execute   (ctrl_t'nin TAMAMI burada tasinir)
  pipeRegRTL #(.T(id_ex_t)) u_id_ex (
    .clk_i(clk_i), .rst_ni(rst_ni),
    .flush_i(id_ex_flush_i), .stall_i(id_ex_stall_i),
    .d_i(id_ex_d_i), .q_o(id_ex_q_o)
  );

  // EX/MEM : execute -> memory  (ex kismi TUKETILDI, artik tasinmiyor)
  pipeRegRTL #(.T(ex_mem_t)) u_ex_mem (
    .clk_i(clk_i), .rst_ni(rst_ni),
    .flush_i(ex_mem_flush_i), .stall_i(1'b0),
    .d_i(ex_mem_d_i), .q_o(ex_mem_q_o)
  );

  // MEM/WB : memory -> writeback  (sadece wb kaldi)
  pipeRegRTL #(.T(mem_wb_t)) u_mem_wb (
    .clk_i(clk_i), .rst_ni(rst_ni),
    .flush_i(1'b0), .stall_i(1'b0),
    .d_i(mem_wb_d_i), .q_o(mem_wb_q_o)
  );

endmodule
