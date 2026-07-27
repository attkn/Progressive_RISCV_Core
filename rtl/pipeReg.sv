// ============================================================================
//  pipeRegRTL : GENEL pipeline register  (tip-parametreli)
// ----------------------------------------------------------------------------
//  Dort pipeline register'i da ayni davranisi paylasir; sadece TASIDIKLARI TIP
//  farklidir. Tek modul yazip dort kez ornekliyoruz (kod tekrari yok, tek yerde
//  duzeltme).
//
//  ONCELIK:  reset > flush > stall > guncelle
//    flush : '0 yaz -> reg_write=0, mem_write=0, valid=0  (ZARARSIZ BALON)
//            ctrl_t'yi struct yapmis olmamizin karsiligi: tek satirda guvenli
//            bubble. Mimari durumu degistiren her sinyal kapanir.
//    stall : mevcut degeri KORU (komut asamada bekler)
//
//  flush ve stall ayni anda gelirse FLUSH kazanir (komutu oldur > beklet).
//  Normal calismada hazard unit bunlari ayni register icin birlikte surmez.
// ============================================================================
module pipeRegRTL #(
  parameter type T = logic
)(
  input  logic clk_i,
  input  logic rst_ni,
  input  logic flush_i,
  input  logic stall_i,
  input  T     d_i,
  output T     q_o
);

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if      (!rst_ni)   q_o <= '0;
    else if (flush_i)   q_o <= '0;    // balon
    else if (!stall_i)  q_o <= d_i;   // ilerle
    // stall: q_o degismez (implicit hold)
  end

endmodule
