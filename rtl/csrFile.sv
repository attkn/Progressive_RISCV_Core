// ============================================================================
//  csrFileRTL : Zicsr motoru + Faz 1 temel CSR'lar  (EX'e asilan CSR birimi)
// ----------------------------------------------------------------------------
//  MOTOR: atomik oku-degistir (CSRRW/CSRRS/CSRRC + immediate).
//    CSRRW : rd=eski; csr=wdata                    (her zaman yazar)
//    CSRRS : rd=eski; csr=eski | wdata             (kaynak x0 ise YAZMAZ)
//    CSRRC : rd=eski; csr=eski & ~wdata            (kaynak x0 ise YAZMAZ)
//    wdata = EX'te secilir: rs1 degeri  ya da  {27'b0, zimm5}
//    src_is_x0 = (rs1/zimm alani == 0)  -> RS/RC yazma bastirmasi
//
//  FAZ 1 CSR SETI:
//    misa            (uygulanan uzantilari core_config toggle'larindan bildirir)
//    mvendorid/marchid/mimpid/mhartid   (makine bilgisi, salt-okunur)
//    mcycle/mcycleh, minstret/minstreth (64-bit sayaclar, yazilabilir)
//    cycle/instret (+h)                 (unprivileged salt-okunur golge)
//    (trap CSR'lari mstatus/mtvec/... -> K2)
//
//  illegal_csr: uygulanmamis adres VEYA salt-okunur CSR'a yazma girisimi.
//    Simdilik sadece SINYAL — trap makinesi (K2) bunu yakalayacak.
//    (privilege kontrolu de K2: Faz 1 M-mode varsayilir.)
// ============================================================================
`include "riscv_imports.svh"

module csrFileRTL #(
  parameter logic [31:0] HART_ID = 32'h0
)(
  input  logic            clk_i,
  input  logic            rst_ni,

  // ---- CSR komut arayuzu (EX'ten) ----
  input  csr_op_e         csr_op_i,        // NONE/RW/RS/RC
  input  logic [11:0]     csr_addr_i,
  input  logic [WIDTH-1:0] wdata_i,        // rs1 degeri veya {27'b0,zimm}
  input  logic            src_is_x0_i,     // RS/RC yazma bastirmasi

  // ---- sayac olayi ----
  input  logic            instret_inc_i,   // bir komut retire oldu (commit)

  // ---- ciktilar ----
  output logic [WIDTH-1:0] rdata_o,        // eski CSR degeri -> WB
  output logic            illegal_csr_o
);

  // --------------------------------------------------------------------------
  //  misa: uygulanan uzantilar (core_config toggle'larindan)
  // --------------------------------------------------------------------------
  localparam logic [31:0] MISA_VALUE =
      (32'h1 << 30)                       // MXL = 1 (RV32)
    | (32'h1 << 8)                        // I (daima)
    | (M_EN ? (32'h1 << 12) : 32'h0)      // M
    | (A_EN ? (32'h1 << 0)  : 32'h0)      // A
    | (C_EN ? (32'h1 << 2)  : 32'h0)      // C
    | (B_EN ? (32'h1 << 1)  : 32'h0)      // B
    | (F_EN ? (32'h1 << 5)  : 32'h0)      // F
    | (V_EN ? (32'h1 << 21) : 32'h0);     // V

  // --------------------------------------------------------------------------
  //  Durum: 64-bit sayaclar (RV32 -> alt/ust 32-bit)
  // --------------------------------------------------------------------------
  logic [31:0] mcycle_q,  mcycleh_q;
  logic [31:0] minstret_q, minstreth_q;

  // --------------------------------------------------------------------------
  //  OKUMA mux'u  + adres gecerli mi (addr_valid)
  // --------------------------------------------------------------------------
  logic addr_valid;
  always_comb begin
    rdata_o    = 32'h0;
    addr_valid = 1'b1;
    unique case (csr_addr_i)
      CSR_MISA      : rdata_o = MISA_VALUE;
      CSR_MVENDORID : rdata_o = 32'h0;
      CSR_MARCHID   : rdata_o = 32'h0;
      CSR_MIMPID    : rdata_o = 32'h0;
      CSR_MHARTID   : rdata_o = HART_ID;
      CSR_MCYCLE    : rdata_o = mcycle_q;
      CSR_MCYCLEH   : rdata_o = mcycleh_q;
      CSR_MINSTRET  : rdata_o = minstret_q;
      CSR_MINSTRETH : rdata_o = minstreth_q;
      CSR_CYCLE     : rdata_o = mcycle_q;      // salt-okunur golge
      CSR_CYCLEH    : rdata_o = mcycleh_q;
      CSR_INSTRET   : rdata_o = minstret_q;
      CSR_INSTRETH  : rdata_o = minstreth_q;
      default       : begin rdata_o = 32'h0; addr_valid = 1'b0; end
    endcase
  end

  // --------------------------------------------------------------------------
  //  YAZMA degeri + yazma izni
  // --------------------------------------------------------------------------
  logic [WIDTH-1:0] wval;
  always_comb begin
    unique case (csr_op_i)
      CSR_OP_RW: wval = wdata_i;
      CSR_OP_RS: wval = rdata_o |  wdata_i;
      CSR_OP_RC: wval = rdata_o & ~wdata_i;
      default  : wval = rdata_o;
    endcase
  end

  logic wr_en;
  always_comb begin
    unique case (csr_op_i)
      CSR_OP_RW           : wr_en = 1'b1;            // her zaman
      CSR_OP_RS, CSR_OP_RC: wr_en = ~src_is_x0_i;    // kaynak x0 ise bastir
      default             : wr_en = 1'b0;
    endcase
  end

  // salt-okunur mu (adres konvansiyonu: csr[11:10]==11)
  logic is_readonly;
  assign is_readonly = (csr_addr_i[11:10] == 2'b11);

  // illegal: gecersiz adres VEYA salt-okunur'a gercekten yazma
  assign illegal_csr_o = (csr_op_i != CSR_OP_NONE)
                       && ( !addr_valid || (wr_en && is_readonly) );

  // --------------------------------------------------------------------------
  //  Sayac guncelleme (yazma-override, yoksa artir; 64-bit tasima)
  // --------------------------------------------------------------------------
  logic [63:0] cyc_q, cyc_n, inst_q, inst_n;
  assign cyc_q  = {mcycleh_q,  mcycle_q};
  assign inst_q = {minstreth_q, minstret_q};

  always_comb begin
    // varsayilan: mcycle her cycle +1
    cyc_n = cyc_q + 64'd1;
    if (wr_en && (csr_addr_i == CSR_MCYCLE))  cyc_n = {cyc_q[63:32], wval};
    if (wr_en && (csr_addr_i == CSR_MCYCLEH)) cyc_n = {wval, cyc_q[31:0]};

    // varsayilan: minstret retire'da +1
    inst_n = inst_q + (instret_inc_i ? 64'd1 : 64'd0);
    if (wr_en && (csr_addr_i == CSR_MINSTRET))  inst_n = {inst_q[63:32], wval};
    if (wr_en && (csr_addr_i == CSR_MINSTRETH)) inst_n = {wval, inst_q[31:0]};
  end

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      mcycle_q <= 32'h0; mcycleh_q <= 32'h0;
      minstret_q <= 32'h0; minstreth_q <= 32'h0;
    end else begin
      mcycle_q    <= cyc_n[31:0];
      mcycleh_q   <= cyc_n[63:32];
      minstret_q  <= inst_n[31:0];
      minstreth_q <= inst_n[63:32];
    end
  end

endmodule
