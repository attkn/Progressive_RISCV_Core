package riscv_types;

    import riscv_opcodes::*;

    // =========================================================================
    // Integer ALU operasyonlari
    // =========================================================================
    typedef enum logic [3:0] {
        ALU_ADD   = 4'd0,
        ALU_SUB   = 4'd1,
        ALU_AND   = 4'd2,
        ALU_OR    = 4'd3,
        ALU_XOR   = 4'd4,
        ALU_SLL   = 4'd5,
        ALU_SRL   = 4'd6,
        ALU_SRA   = 4'd7,
        ALU_SLT   = 4'd8,
        ALU_SLTU  = 4'd9,
        ALU_LUI   = 4'd10,   // rd = imm        (operand B'yi gecir)
        ALU_AUIPC = 4'd11    // rd = pc + imm
    } aluOpInt_e;

    // =========================================================================
    // Branch karsilastirma operasyonlari
    // =========================================================================
    typedef enum logic [2:0] {
        ALU_BEQ  = 3'd0,
        ALU_BNE  = 3'd1,
        ALU_BLT  = 3'd2,
        ALU_BGE  = 3'd3,
        ALU_BLTU = 3'd4,
        ALU_BGEU = 3'd5
    } aluOpBranch_e;

    // =========================================================================
    // Bellek erisim genisligi
    //   LOAD  : loadType_e  + isLoadSigned
    //   STORE : storeType_e (isaret kavrami yok)
    // =========================================================================
    typedef enum logic [1:0] {
        BYTE = 2'd0,
        HALF = 2'd1,
        WORD = 2'd2
    } loadType_e;

    typedef enum logic [1:0] {
        STORE_BYTE = 2'd0,
        STORE_HALF = 2'd1,
        STORE_WORD = 2'd2
    } storeType_e;

    // =========================================================================
    // Writeback kaynagi
    //   Datapath'te "memoryReadEn | JALen | ..." turetmesi yerine acik secim.
    //   CSR ve FP eklendiginde bu tercih kendini odeyecek.
    // =========================================================================
    typedef enum logic [1:0] {
        WB_ALU = 2'd0,   // ALU sonucu
        WB_MEM = 2'd1,   // Bellekten okunan (isaret/sifir uzatilmis) veri
        WB_PC4 = 2'd2,   // pc + 4  (JAL / JALR link adresi)
        WB_CSR = 2'd3    // CSR okuma degeri (Zicsr)
    } wbSel_e;

    // =========================================================================
    // Kontrol sinyali demeti
    //
    //  isStoreEn  vs  memoryWriteEn  AYRIMI (onemli):
    //    isStoreEn     : saf decode ciktisi -- "bu komut bir store'dur".
    //                    Hicbir sey tarafindan maskelenmez. Hazard mantigi,
    //                    LSU ve store buffer bu biti kullanir.
    //    memoryWriteEn : gercek yazma strobe'u. Pipeline'da su sekilde
    //                    nitelenecek:
    //                      memoryWriteEn = isStoreEn & ~flush & ~exception
    //                                                 & ~misaligned
    //                    Yanlis tahmin edilen branch'in golgesindeki ya da
    //                    trap alan bir store BELLEGE YAZMAMALIDIR; ama yine
    //                    de "store"dur. Iki bit ayri durmazsa bu bilgi kaybolur.
    //    Tek cevrimli tasarimda ikisi ayni degeri tasir.
    // =========================================================================
    

    // =========================================================================
    // Immediate formatlari (ISA spec Bolum 2.3, Sekil 2.4)
    //
    //   IMM_NONE : R-type / OP-FP -- immediate yok
    //   IMM_I    : LOAD, OP-IMM, JALR, SYSTEM(CSR adresi), FLW
    //   IMM_S    : STORE, FSW
    //   IMM_B    : BRANCH        (LSB daima 0)
    //   IMM_U    : LUI, AUIPC    (alt 12 bit daima 0)
    //   IMM_J    : JAL           (LSB daima 0)
    //   IMM_Z    : Zicsr immediate formu -- uimm[4:0] = instr[19:15],
    //              SIFIR uzatilir (isaret uzatilmaz!)
    // =========================================================================
    typedef enum logic [2:0] {
        IMM_NONE = 3'd0,
        IMM_I    = 3'd1,
        IMM_S    = 3'd2,
        IMM_B    = 3'd3,
        IMM_U    = 3'd4,
        IMM_J    = 3'd5,
        IMM_Z    = 3'd6
    } imm_type_e;

    // =========================================================================
    // Exception cause kodlari (mcause)
    //   MSB = 1 -> interrupt,  MSB = 0 -> exception
    // =========================================================================
    localparam logic [3:0] EXC_INSTR_ADDR_MISALIGNED = 4'd0;
    localparam logic [3:0] EXC_INSTR_ACCESS_FAULT    = 4'd1;
    localparam logic [3:0] EXC_ILLEGAL_INSTR         = 4'd2;
    localparam logic [3:0] EXC_BREAKPOINT            = 4'd3;
    localparam logic [3:0] EXC_LOAD_ADDR_MISALIGNED  = 4'd4;
    localparam logic [3:0] EXC_LOAD_ACCESS_FAULT     = 4'd5;
    localparam logic [3:0] EXC_STORE_ADDR_MISALIGNED = 4'd6;
    localparam logic [3:0] EXC_STORE_ACCESS_FAULT    = 4'd7;
    localparam logic [3:0] EXC_ECALL_M               = 4'd11;

    localparam logic [3:0] IRQ_M_SOFTWARE = 4'd3;
    localparam logic [3:0] IRQ_M_TIMER    = 4'd7;
    localparam logic [3:0] IRQ_M_EXTERNAL = 4'd11;
    
    typedef struct packed {
        aluOpInt_e    aluOp;
        imm_type_e    immType;             // immGen'e format bilgisi
        logic         isLoadSigned;
        logic         registerFileWriteEn;
        logic         immEn;               // ALU operand B: 0=rs2, 1=imm
        loadType_e    loadType;
        logic         isStoreEn;           // decode: "bu bir store komutu"
        logic         memoryWriteEn;       // nitelenmis yazma strobe'u
        storeType_e   storeType;
        logic         memoryReadEn;
        logic         isBranchOpRunning;
        aluOpBranch_e aluBranchOp;
        logic         JALen;
        logic         JALRen;
        wbSel_e       wbSel;
    } ctrl_t;
    
endpackage
