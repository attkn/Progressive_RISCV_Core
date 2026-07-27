// ============================================================================
//  forwardingRTL : bypass (forwarding) birimi  —  KOMBINASYONEL
// ----------------------------------------------------------------------------
//  Sorun: EX'teki komut, henuz register file'a YAZILMAMIS bir sonuca ihtiyac
//  duyabilir (RAW hazard). Cozum: sonucu geç asamalardan EX'e geri yonlendir.
//
//  KURALLAR (siralama onemli):
//   1) EX/MEM ONCELIKLI  — daha yeni komut, daha taze deger.
//      (iki asama da ayni rd'ye yaziyorsa EX/MEM kazanir; yoksa ESKI deger alinir)
//   2) reg_write=0 ise iletme (o komut zaten rd yazmiyor)
//   3) rd == x0 ise ASLA iletme (x0 daima sifir; iletmek 0'i bozar)
//
//  Load-use bu birimin isi DEGIL: load verisi MEM'de hazir olur, EX'te henuz
//  yoktur -> hazard unit STALL eder (bkz. hazardRTL).
// ============================================================================
`include "riscv_imports.svh"

module forwardingRTL (
  // EX'teki komutun kaynak register'lari (ID/EX'ten)
  input  logic [RS_ADDRESS-1:0] ex_rs1_i,
  input  logic [RS_ADDRESS-1:0] ex_rs2_i,
  // EX/MEM asamasindaki komut
  input  logic                  exmem_reg_write_i,
  input  logic [RS_ADDRESS-1:0] exmem_rd_i,
  // MEM/WB asamasindaki komut
  input  logic                  memwb_reg_write_i,
  input  logic [RS_ADDRESS-1:0] memwb_rd_i,
  // secim
  output fwd_sel_e              fwd_a_o,      // operand A (rs1)
  output fwd_sel_e              fwd_b_o       // operand B (rs2)
);

  // tek kaynak icin ortak kural
  function automatic fwd_sel_e pick(input logic [RS_ADDRESS-1:0] src);
    if (exmem_reg_write_i && (exmem_rd_i != '0) && (exmem_rd_i == src))
      pick = FWD_EX_MEM;                       // 1) en taze
    else if (memwb_reg_write_i && (memwb_rd_i != '0) && (memwb_rd_i == src))
      pick = FWD_MEM_WB;
    else
      pick = FWD_NONE;                         // register file
  endfunction

  always_comb begin
    fwd_a_o = pick(ex_rs1_i);
    fwd_b_o = pick(ex_rs2_i);
  end

endmodule
