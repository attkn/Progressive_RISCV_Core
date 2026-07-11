// ============================================================================
//  dividerRTL  --  Radix-4 tamsayi bolucu  (FPGA-sentezlenebilir, parametrik)
//  RISC-V M uzantisi:  DIV / DIVU / REM / REMU
//
//  - Her cevrimde 2 bolum biti          -> WIDTH/2 iterasyon (32-bit icin 16)
//  - Karsilastirma-tabanli rakam secimi -> kismi kalani D, 2D, 3D ile karsilastir
//  - Kismi kalan daima [0, D)           -> normalizasyon YOK, kalan dogrudan dogru
//  - Bolum ve kalan ayni anda uretilir; mode_i sadece isaretliligi secer
//
//  Arayuz
//    mode_i = 1 : isaretli   (DIV/REM)
//    mode_i = 0 : isaretsiz  (DIVU/REMU)
//    start_i    : 1 cevrim yukselt  -> hesaplama baslar
//    done_o     : sonuc hazir oldugunda 1 cevrim darbe; o cevrimde cikislar gecerli
//    Gecikme    : ~WIDTH/2 + 2 cevrim  (ozel durumda ~2)
//
//  Sentez notlari
//    - Tamamen sentezlenebilir: latch yok, kombinasyonel dongu yok.
//    - Kritik yol: (WIDTH+2)-bit karsilastirma/cikarma (tek radix-4 adimi).
//    - Veri yolu register'lari sifirlanmaz (kullanimdan once yuklenir) -> daha
//      az reset agi, daha iyi zamanlama. Yalnizca kontrol register'lari sifirlanir.
//    - Reset: asenkron, aktif-dusuk (FF async-clear'e maplenir). Akisin senkron
//      reset istiyorsa duyarlilik listesinden 'negedge rst_ni' cikarilip
//      reset dali 'if(!rst_ni)' olarak clk ile ornekleneblir.
// ============================================================================
import  riscv_pgk::*;
module dividerRTL(
    input  logic              clk_i,
    input  logic              rst_ni,       // asenkron, aktif-dusuk
    input  logic              mode_i,       // 1 = isaretli, 0 = isaretsiz
    input  logic              start_i,
    input  logic [WIDTH-1:0]  dividend_i,   // bolunen
    input  logic [WIDTH-1:0]  divider_i,    // bolen
    output logic [WIDTH-1:0]  remainder_o,  // kalan
    output logic [WIDTH-1:0]  quantient_o,  // bolum
    output logic              done_o
);

    localparam int PW    = WIDTH + 2;             // kismi kalan / 3D genisligi
    localparam int NITER = WIDTH / 2;             // radix-4: cevrim basina 2 bit
    localparam int CW    = $clog2(NITER + 1);     // iterasyon sayaci genisligi

    typedef enum logic [1:0] {S_IDLE, S_RUN, S_DONE} state_e;
    state_e state;

    // ---- girisden turetilen yardimcilar (kombinasyonel) ----
    logic             dvd_neg, dvs_neg, ov;
    logic [WIDTH-1:0] dvd_mag, dvs_mag;

    always_comb begin
        dvd_neg = mode_i & dividend_i[WIDTH-1];
        dvs_neg = mode_i & divider_i [WIDTH-1];
        dvd_mag = dvd_neg ? (~dividend_i + 1'b1) : dividend_i;
        dvs_mag = dvs_neg ? (~divider_i  + 1'b1) : divider_i;
        ov      = mode_i & (dividend_i == {1'b1, {(WIDTH-1){1'b0}}}) & (&divider_i);
    end

    // ---- durum register'lari ----
    logic              q_neg, r_neg, special;
    logic [WIDTH-1:0]  spec_quo, spec_rem;
    logic [PW-1:0]     d1, d2, d3;               // D, 2D, 3D
    logic [WIDTH-1:0]  A;                        // kalan bolunen bitleri (MSB'den tuketilir)
    logic [PW-1:0]     P;                        // kismi kalan (her sinirda < D)
    logic [WIDTH-1:0]  Q;                        // bolum (biriktirilir)
    logic [CW-1:0]     cnt;

    // ---- tek radix-4 adimi (kombinasyonel) ----
    logic [PW-1:0]     cur;                      // 4*P + sonraki 2 bit
    logic [1:0]        qdig;                     // bu adimin rakami {0,1,2,3}
    logic [PW-1:0]     Pn;                       // P - qdig*D

    always_comb begin
        cur = (P << 2) | ({{(PW-WIDTH){1'b0}}, A} >> (WIDTH-2)); // = 4*P + ust2(A)
        if      (cur >= d3) begin qdig = 2'd3; Pn = cur - d3; end
        else if (cur >= d2) begin qdig = 2'd2; Pn = cur - d2; end
        else if (cur >= d1) begin qdig = 2'd1; Pn = cur - d1; end
        else                begin qdig = 2'd0; Pn = cur;      end
    end

    // ---- FSM + veri yolu ----
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            state       <= S_IDLE;
            done_o      <= 1'b0;
            remainder_o <= '0;
            quantient_o <= '0;
        end else begin
            case (state)
                // -------------------------------------------------
                S_IDLE: begin
                    done_o <= 1'b0;
                    if (start_i) begin
                        q_neg <= dvd_neg ^ dvs_neg;          // bolum isareti
                        r_neg <= dvd_neg;                     // kalan isareti = bolunenin

                        d1 <= {2'b00, dvs_mag};               // D
                        d2 <= {1'b0,  dvs_mag, 1'b0};         // 2D
                        d3 <= {2'b00, dvs_mag} + {1'b0, dvs_mag, 1'b0}; // 3D

                        P   <= '0;
                        Q   <= '0;
                        A   <= dvd_mag;
                        cnt <= '0;

                        if (divider_i == '0) begin            // sifira bolme (RISC-V)
                            special  <= 1'b1;
                            spec_quo <= '1;                   // hepsi 1
                            spec_rem <= dividend_i;           // kalan = bolunen
                            state    <= S_DONE;
                        end else if (ov) begin                // isaretli tasma MIN/-1
                            special  <= 1'b1;
                            spec_quo <= dividend_i;           // = MIN
                            spec_rem <= '0;
                            state    <= S_DONE;
                        end else begin
                            special <= 1'b0;
                            state   <= S_RUN;
                        end
                    end
                end
                // -------------------------------------------------
                S_RUN: begin
                    P   <= Pn;                                     // 4P + 2bit - qdig*D
                    Q   <= (Q << 2) | {{(WIDTH-2){1'b0}}, qdig};   // 2-bit haneyi kaydir
                    A   <= A << 2;                                 // 2 bolunen bitini tuket
                    cnt <= cnt + 1'b1;
                    if (cnt == CW'(NITER-1))
                        state <= S_DONE;
                end
                // -------------------------------------------------
                S_DONE: begin
                    if (special) begin
                        quantient_o <= spec_quo;
                        remainder_o <= spec_rem;
                    end else begin
                        quantient_o <= q_neg ? (~Q + 1'b1) : Q;
                        remainder_o <= r_neg ? WIDTH'(~P + 1'b1) : WIDTH'(P); // P ust 2 biti daima 0
                    end
                    done_o <= 1'b1;
                    state  <= S_IDLE;
                end
                // -------------------------------------------------
                default: state <= S_IDLE;
            endcase
        end
    end

endmodule