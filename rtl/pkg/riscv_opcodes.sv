package riscv_opcodes;
    typedef enum logic [6:0] {
        // RV32I
        OPC_LOAD     = 7'b0000011,
        OPC_MISC_MEM = 7'b0001111,
        OPC_OP_IMM   = 7'b0010011,
        OPC_AUIPC    = 7'b0010111,
        OPC_STORE    = 7'b0100011,
        OPC_OP       = 7'b0110011,   // RV32M de bunu kullanir (funct7=0000001)
        OPC_LUI      = 7'b0110111,
        OPC_BRANCH   = 7'b1100011,
        OPC_JALR     = 7'b1100111,
        OPC_JAL      = 7'b1101111,
        OPC_SYSTEM   = 7'b1110011,   // Zicsr + ECALL/EBREAK

        OPC_LOAD_FP  = 7'b0000111,
        OPC_STORE_FP = 7'b0100111,
        OPC_MADD     = 7'b1000011,
        OPC_MSUB     = 7'b1000111,
        OPC_NMSUB    = 7'b1001011,
        OPC_NMADD    = 7'b1001111,
        OPC_OP_FP    = 7'b1010011,

        OPC_CUSTOM_0 = 7'b0001011,
        OPC_CUSTOM_1 = 7'b0101011,
        OPC_CUSTOM_2 = 7'b1011011,
        OPC_CUSTOM_3 = 7'b1111011
    } opcode_e;

    // OP / OP-IMM
    localparam logic [2:0] F3_ADD_SUB = 3'b000;
    localparam logic [2:0] F3_SLL     = 3'b001;
    localparam logic [2:0] F3_SLT     = 3'b010;
    localparam logic [2:0] F3_SLTU    = 3'b011;
    localparam logic [2:0] F3_XOR     = 3'b100;
    localparam logic [2:0] F3_SR      = 3'b101;   // SRL / SRA
    localparam logic [2:0] F3_OR      = 3'b110;
    localparam logic [2:0] F3_AND     = 3'b111;

    // BRANCH
    localparam logic [2:0] F3_BEQ  = 3'b000;
    localparam logic [2:0] F3_BNE  = 3'b001;
    localparam logic [2:0] F3_BLT  = 3'b100;
    localparam logic [2:0] F3_BGE  = 3'b101;
    localparam logic [2:0] F3_BLTU = 3'b110;
    localparam logic [2:0] F3_BGEU = 3'b111;

    // LOAD
    localparam logic [2:0] F3_LB  = 3'b000;
    localparam logic [2:0] F3_LH  = 3'b001;
    localparam logic [2:0] F3_LW  = 3'b010;
    localparam logic [2:0] F3_LBU = 3'b100;
    localparam logic [2:0] F3_LHU = 3'b101;

    // STORE
    localparam logic [2:0] F3_SB = 3'b000;
    localparam logic [2:0] F3_SH = 3'b001;
    localparam logic [2:0] F3_SW = 3'b010;

    // MISC-MEM
    localparam logic [2:0] F3_FENCE   = 3'b000;
    localparam logic [2:0] F3_FENCE_I = 3'b001;

    // SYSTEM
    localparam logic [2:0]  F3_PRIV   = 3'b000;   // ECALL / EBREAK / xRET
    localparam logic [2:0]  F3_CSRRW  = 3'b001;
    localparam logic [2:0]  F3_CSRRS  = 3'b010;
    localparam logic [2:0]  F3_CSRRC  = 3'b011;
    localparam logic [2:0]  F3_CSRRWI = 3'b101;
    localparam logic [2:0]  F3_CSRRSI = 3'b110;
    localparam logic [2:0]  F3_CSRRCI = 3'b111;
    localparam logic [11:0] SYS_IMM_ECALL  = 12'h000;
    localparam logic [11:0] SYS_IMM_EBREAK = 12'h001;

    // funct7
    localparam logic [6:0] F7_BASE = 7'b0000000;  // ADD, SRL, SLLI...
    localparam logic [6:0] F7_ALT  = 7'b0100000;  // SUB, SRA, SRAI
    localparam logic [6:0] F7_MULDIV = 7'b0000001; // RV32M

    // 32-bit komut isareti (RVC ayirt etmek icin)
    localparam logic [1:0] INSTR_32B = 2'b11;

endpackage
