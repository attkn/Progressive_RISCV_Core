module aluInt   import riscv_opcodes::*, riscv_types::*;
 #(parameter int WIDTH = 32) (
    input  aluOpInt_e        aluOp_i,
    input  logic [WIDTH-1:0] rd1_i,
    input  logic [WIDTH-1:0] rd2_i,
    input  logic [WIDTH-1:0] pc_i,         // AUIPC icin
    // shift_size[5] RV32'de kullanilmaz (RV64 icin ayrilmis)
    /* verilator lint_off UNUSEDSIGNAL */
    input  logic [5:0]       shift_size,
    /* verilator lint_on UNUSEDSIGNAL */
    output logic [WIDTH-1:0] result_o
);

    localparam int SHAMT_W = $clog2(WIDTH);

    // -------------------------------------------------------------------------
    // Bit ters cevirme -- sadece kablo, sifir alan
    // -------------------------------------------------------------------------
    function automatic logic [WIDTH-1:0] rev (input logic [WIDTH-1:0] x);
        for (int i = 0; i < WIDTH; i++) rev[i] = x[WIDTH-1-i];
    endfunction

    // -------------------------------------------------------------------------
    // Operasyon kod cozumu
    // -------------------------------------------------------------------------
    logic isSub, isSlt, isSltu, isSll, isSra, isAuipc;

    assign isSub   = (aluOp_i == ALU_SUB);
    assign isSlt   = (aluOp_i == ALU_SLT);
    assign isSltu  = (aluOp_i == ALU_SLTU);
    assign isSll   = (aluOp_i == ALU_SLL);
    assign isSra   = (aluOp_i == ALU_SRA);
    assign isAuipc = (aluOp_i == ALU_AUIPC);

    // =========================================================================
    // PAYLASILAN TOPLAYICI  ->  ADD / SUB / SLT / SLTU / AUIPC
    // =========================================================================
    logic             doSubtract;
    logic [WIDTH-1:0] addOpA, addOpB;
    logic [WIDTH:0]   addResult;      // [WIDTH] = carry-out
    logic [WIDTH-1:0] sum;
    logic             carryOut;

    // SLT/SLTU de fark uzerinden hesaplandigi icin cikarma yapar
    assign doSubtract = isSub | isSlt | isSltu;

    // AUIPC: pc + imm   |   digerleri: rs1 + operandB
    assign addOpA = isAuipc ? pc_i : rd1_i;
    assign addOpB = doSubtract ? ~rd2_i : rd2_i;

    assign addResult = {1'b0, addOpA} + {1'b0, addOpB} + {{WIDTH{1'b0}}, doSubtract};
    assign sum       = addResult[WIDTH-1:0];
    assign carryOut  = addResult[WIDTH];

    // ---- Karsilastirma sonuclari: toplayicidan bedava ----
    logic signBitA, signBitB, ltUnsigned, ltSigned;

    assign signBitA = rd1_i[WIDTH-1];
    assign signBitB = rd2_i[WIDTH-1];

    // a-b'de borrow olustuysa (carry-out = 0) a < b demektir
    assign ltUnsigned = ~carryOut;

    // Isaretler farkliysa negatif olan kucuktur; ayni ise farkin isareti belirler
    assign ltSigned = (signBitA ^ signBitB) ? signBitA : sum[WIDTH-1];

    // =========================================================================
    // PAYLASILAN SHIFTER  ->  SLL / SRL / SRA
    // =========================================================================
    logic [SHAMT_W-1:0] shamt;
    logic [WIDTH-1:0]   shiftSrc;
    logic [WIDTH:0]     shiftOperand;   // +1 bit isaret uzantisi
    /* verilator lint_off UNUSEDSIGNAL */
    logic [WIDTH:0]     shiftRaw;   // [WIDTH] isaret uzantisi, bilerek atiliyor
    /* verilator lint_on UNUSEDSIGNAL */
    logic [WIDTH-1:0]   shiftResult;

    assign shamt = shift_size[SHAMT_W-1:0];

    // SLL icin girisi ters cevir
    assign shiftSrc = isSll ? rev(rd1_i) : rd1_i;

    // SRA'da MSB'yi uzat, digerlerinde 0 besle -> tek saga kaydirici yeter
    assign shiftOperand = {isSra & shiftSrc[WIDTH-1], shiftSrc};
    assign shiftRaw     = $unsigned($signed(shiftOperand) >>> shamt);

    // SLL icin cikisi geri ters cevir
    assign shiftResult = isSll ? rev(shiftRaw[WIDTH-1:0]) : shiftRaw[WIDTH-1:0];

    // =========================================================================
    // MANTIK BIRIMI (paylasim karli degil, ayri)
    // =========================================================================
    logic [WIDTH-1:0] andResult, orResult, xorResult;

    assign andResult = rd1_i & rd2_i;
    assign orResult  = rd1_i | rd2_i;
    assign xorResult = rd1_i ^ rd2_i;

    // =========================================================================
    // CIKIS MUX'I
    // =========================================================================
    always_comb begin
        case (aluOp_i)
            ALU_ADD,
            ALU_SUB,
            ALU_AUIPC : result_o = sum;                              // paylasilan toplayici

            ALU_SLT   : result_o = {{(WIDTH-1){1'b0}}, ltSigned};
            ALU_SLTU  : result_o = {{(WIDTH-1){1'b0}}, ltUnsigned};

            ALU_SLL,
            ALU_SRL,
            ALU_SRA   : result_o = shiftResult;                      // paylasilan shifter

            ALU_AND   : result_o = andResult;
            ALU_OR    : result_o = orResult;
            ALU_XOR   : result_o = xorResult;

            ALU_LUI   : result_o = rd2_i;                            // rd = U-imm (kablo)

            default   : result_o = '0;
        endcase
    end

endmodule
