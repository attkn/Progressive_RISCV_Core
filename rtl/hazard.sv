// ============================================================================
//  hazardRTL : hazard tespiti + stall/flush uretimi  —  KOMBINASYONEL
// ----------------------------------------------------------------------------
//  Uc tur tehlike yonetilir:
//
//  1) LOAD-USE (veri tehlikesi, forwarding ile COZULEMEZ)
//     ID'deki komut, EX'teki bir LOAD'in rd'sini okuyorsa: load verisi ancak
//     MEM sonunda hazir olur -> 1 cycle STALL + EX'e balon.
//
//  2) COK-CYCLE BIRIM MESGUL (mul/div/fpu calisirken)
//     EX'i dondur, on tarafi (PC, IF/ID, ID/EX) dondur, MEM'e balon gonder.
//
//  3) KONTROL TEHLIKESI (branch taken / jump)
//     Branch EX'te cozuluyor -> IF/ID ve ID/EX'teki (yanlis yoldan gelen)
//     komutlar FLUSH edilir.
//
//  Oncelik: stall > flush (birim mesgulken yeni is alinmaz).
//  FLUSH = ilgili pipeline register'ina '0 yaz -> reg_write=0, mem_write=0
//          (mimari durumu degistirmeyen zararsiz balon).
// ============================================================================
`include "riscv_imports.svh"

module hazardRTL (
  // ID asamasindaki komutun kaynak register'lari (IF/ID'den cozulen)
  input  logic [RS_ADDRESS-1:0] id_rs1_i,
  input  logic [RS_ADDRESS-1:0] id_rs2_i,
  input  logic                  id_uses_rs1_i,   // bu komut rs1 okuyor mu
  input  logic                  id_uses_rs2_i,   // bu komut rs2 okuyor mu

  // EX asamasindaki komut (ID/EX)
  input  logic                  ex_mem_read_i,   // EX'teki komut LOAD mu
  input  logic [RS_ADDRESS-1:0] ex_rd_i,

  // cok-cycle birim durumu (muldiv_unit / fpu busy)
  input  logic                  ex_unit_busy_i,

  // dallanma sonucu (EX'te cozuldu)
  input  logic                  branch_taken_i,
  input  logic                  jump_i,

  // ---- pipeline kontrol ciktilari ----
  output logic                  pc_stall_o,
  output logic                  if_id_stall_o,
  output logic                  if_id_flush_o,
  output logic                  id_ex_flush_o,   // EX'e balon
  output logic                  ex_mem_flush_o,  // MEM'e balon (cok-cycle)
  output logic                  load_use_o       // gozlem/debug
);

  // ---- 1) load-use tespiti ----
  logic rs1_hit, rs2_hit;
  assign rs1_hit = id_uses_rs1_i && (id_rs1_i == ex_rd_i);
  assign rs2_hit = id_uses_rs2_i && (id_rs2_i == ex_rd_i);

  assign load_use_o = ex_mem_read_i && (ex_rd_i != '0) && (rs1_hit || rs2_hit);

  // ---- 2) kontrol tehlikesi ----
  logic redirect;
  assign redirect = branch_taken_i || jump_i;

  // ---- 3) birlestir (oncelik: birim mesgul > load-use > redirect) ----
  always_comb begin
    pc_stall_o     = 1'b0;
    if_id_stall_o  = 1'b0;
    if_id_flush_o  = 1'b0;
    id_ex_flush_o  = 1'b0;
    ex_mem_flush_o = 1'b0;

    if (ex_unit_busy_i) begin
      // cok-cycle birim calisiyor: her seyi dondur, MEM'e balon
      pc_stall_o     = 1'b1;
      if_id_stall_o  = 1'b1;
      id_ex_flush_o  = 1'b0;      // ID/EX DONDURULUR (flush degil)
      ex_mem_flush_o = 1'b1;
    end
    else if (load_use_o) begin
      // 1 cycle bekle, EX'e balon gonder
      pc_stall_o    = 1'b1;
      if_id_stall_o = 1'b1;
      id_ex_flush_o = 1'b1;
    end
    else if (redirect) begin
      // yanlis yoldan gelen iki komutu temizle
      if_id_flush_o = 1'b1;
      id_ex_flush_o = 1'b1;
    end
  end

endmodule
