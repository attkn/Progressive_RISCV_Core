// =============================================================================
//  riscv_opcodes.sv
//  ---------------------------------------------------------------------------
//  RV32IMFC_Zicsr_Zifencei  --  ISA kodlama sabitleri
//
//  Bu paket SADECE ISA spec'inden gelen sabit bit desenlerini icerir.
//  Mimari tercihlere ait tipler (ctrl_t, aluOpInt_e, ...) riscv_types'tadir.
//
//  Kaynak: RISC-V Unprivileged ISA Spec v2.2 / v20191213
// =============================================================================

package riscv_opcodes;

    // =========================================================================
    // Komut alan genislikleri ve bit pozisyonlari
    // =========================================================================
    localparam int XLEN     = 32;
    localparam int RS       = 5;
    localparam int FUNC7       = 7;
    localparam int FUNC3       = 3;
    localparam int SHIFT       = 5;
    localparam int OPCODE   = 7;
    localparam int FUNCT3   = 3;
    localparam int FUNCT7   = 7;
    localparam int FUNCT12  = 12;
    localparam int REG_ADDR = 5;    // rs1 / rs2 / rd
    localparam int SHAMT    = 5;    // RV32 shift miktari
    localparam int CSR_ADDR = 12;
    localparam int unsigned PC_DEFAULT = 0;
    localparam int unsigned INST_MEM_LENGTH = 1024;

    // instr[N] konumlari (decode icin)
    localparam int OPCODE_LSB = 0;
    localparam int RD_LSB     = 7;
    localparam int FUNCT3_LSB = 12;
    localparam int RS1_LSB    = 15;
    localparam int RS2_LSB    = 20;
    localparam int FUNCT7_LSB = 25;

    // OP / OP-IMM icinde funct7[5] -> SUB / SRA ayrimi
    localparam int F7_ALT_BIT = FUNCT7 - 2;   // = 5

    // =========================================================================
    // Komut uzunlugu (RVC ayrimi)
    //   instr[1:0] != 2'b11 -> 16-bit (compressed)
    //   instr[1:0] == 2'b11 -> 32-bit
    // =========================================================================
    localparam logic [1:0] INSTR_32B = 2'b11;

    // =========================================================================
    // OPCODE  (instr[6:0])
    // =========================================================================
    typedef enum logic [OPCODE-1:0] {
        // ---- RV32I ----
        OPC_LOAD     = 7'b0000011,
        OPC_MISC_MEM = 7'b0001111,   // FENCE / FENCE.I
        OPC_OP_IMM   = 7'b0010011,
        OPC_AUIPC    = 7'b0010111,
        OPC_STORE    = 7'b0100011,
        OPC_OP       = 7'b0110011,   // RV32M de burayi kullanir (funct7=0000001)
        OPC_LUI      = 7'b0110111,
        OPC_BRANCH   = 7'b1100011,
        OPC_JALR     = 7'b1100111,
        OPC_JAL      = 7'b1101111,
        OPC_SYSTEM   = 7'b1110011,   // Zicsr + ECALL/EBREAK/MRET/WFI

        // ---- RV32F ----
        OPC_LOAD_FP  = 7'b0000111,   // FLW
        OPC_STORE_FP = 7'b0100111,   // FSW
        OPC_MADD     = 7'b1000011,   // FMADD.S
        OPC_MSUB     = 7'b1000111,   // FMSUB.S
        OPC_NMSUB    = 7'b1001011,   // FNMSUB.S
        OPC_NMADD    = 7'b1001111,   // FNMADD.S
        OPC_OP_FP    = 7'b1010011,

        // ---- Custom ----
        OPC_CUSTOM_0 = 7'b0001011,
        OPC_CUSTOM_1 = 7'b0101011,
        OPC_CUSTOM_2 = 7'b1011011,
        OPC_CUSTOM_3 = 7'b1111011
    } opcode_e;

    

    // -------------------------------------------------------------------------
    // Immediate alan konumlari (immGen icin)
    //   RISC-V kodlamasi isaret bitini DAIMA instr[31]'e koyar -- bu sayede
    //   isaret uzatma mantigi immediate tipinden bagimsizdir.
    // -------------------------------------------------------------------------
    localparam int IMM_SIGN_BIT = 31;      // her formatta isaret biti

    // I-type : instr[31:20]
    localparam int IMM_I_MSB = 31;
    localparam int IMM_I_LSB = 20;

    // S-type : instr[31:25] (ust) + instr[11:7] (alt)
    localparam int IMM_S_HI_MSB = 31;
    localparam int IMM_S_HI_LSB = 25;
    localparam int IMM_S_LO_MSB = 11;
    localparam int IMM_S_LO_LSB = 7;

    // B-type : {instr[31], instr[7], instr[30:25], instr[11:8], 1'b0}
    localparam int IMM_B_BIT11  = 7;       // imm[11] tek basina burada
    localparam int IMM_B_HI_MSB = 30;      // imm[10:5]
    localparam int IMM_B_HI_LSB = 25;
    localparam int IMM_B_LO_MSB = 11;      // imm[4:1]
    localparam int IMM_B_LO_LSB = 8;

    // U-type : instr[31:12] << 12
    localparam int IMM_U_MSB = 31;
    localparam int IMM_U_LSB = 12;

    // J-type : {instr[31], instr[19:12], instr[20], instr[30:21], 1'b0}
    localparam int IMM_J_BIT11  = 20;      // imm[11] tek basina burada
    localparam int IMM_J_HI_MSB = 19;      // imm[19:12]
    localparam int IMM_J_HI_LSB = 12;
    localparam int IMM_J_LO_MSB = 30;      // imm[10:1]
    localparam int IMM_J_LO_LSB = 21;

    // Z-type (Zicsr) : instr[19:15], sifir uzatilir
    localparam int IMM_Z_MSB = 19;
    localparam int IMM_Z_LSB = 15;

    // =========================================================================
    // funct7  (instr[31:25])
    //   DIKKAT: funct7 sadece OPC_OP'ta ve OP-IMM'in shift komutlarinda
    //   anlamlidir. Diger OP-IMM komutlarinda bu bitler imm[11:5]'tir.
    // =========================================================================
    localparam logic [FUNCT7-1:0] F7_BASE   = 7'b0000000;  // ADD, SRL, SLLI, SRLI
    localparam logic [FUNCT7-1:0] F7_ALT    = 7'b0100000;  // SUB, SRA, SRAI
    localparam logic [FUNCT7-1:0] F7_MULDIV = 7'b0000001;  // RV32M

    // =========================================================================
    // RV32I : OP / OP-IMM funct3
    // =========================================================================
    localparam logic [FUNCT3-1:0] F3_ADD_SUB = 3'b000;
    localparam logic [FUNCT3-1:0] F3_SLL     = 3'b001;
    localparam logic [FUNCT3-1:0] F3_SLT     = 3'b010;
    localparam logic [FUNCT3-1:0] F3_SLTU    = 3'b011;
    localparam logic [FUNCT3-1:0] F3_XOR     = 3'b100;
    localparam logic [FUNCT3-1:0] F3_SR      = 3'b101;   // SRL / SRA
    localparam logic [FUNCT3-1:0] F3_OR      = 3'b110;
    localparam logic [FUNCT3-1:0] F3_AND     = 3'b111;

    // ---- BRANCH ----
    localparam logic [FUNCT3-1:0] F3_BEQ  = 3'b000;
    localparam logic [FUNCT3-1:0] F3_BNE  = 3'b001;
    localparam logic [FUNCT3-1:0] F3_BLT  = 3'b100;
    localparam logic [FUNCT3-1:0] F3_BGE  = 3'b101;
    localparam logic [FUNCT3-1:0] F3_BLTU = 3'b110;
    localparam logic [FUNCT3-1:0] F3_BGEU = 3'b111;

    // ---- LOAD ----
    localparam logic [FUNCT3-1:0] F3_LB  = 3'b000;
    localparam logic [FUNCT3-1:0] F3_LH  = 3'b001;
    localparam logic [FUNCT3-1:0] F3_LW  = 3'b010;
    localparam logic [FUNCT3-1:0] F3_LBU = 3'b100;
    localparam logic [FUNCT3-1:0] F3_LHU = 3'b101;

    // ---- STORE ----
    localparam logic [FUNCT3-1:0] F3_SB = 3'b000;
    localparam logic [FUNCT3-1:0] F3_SH = 3'b001;
    localparam logic [FUNCT3-1:0] F3_SW = 3'b010;

    // ---- JALR (tek gecerli funct3) ----
    localparam logic [FUNCT3-1:0] F3_JALR = 3'b000;

    // ---- MISC-MEM ----
    localparam logic [FUNCT3-1:0] F3_FENCE   = 3'b000;
    localparam logic [FUNCT3-1:0] F3_FENCE_I = 3'b001;   // Zifencei

    // =========================================================================
    // RV32M : OPC_OP + funct7 == F7_MULDIV
    // =========================================================================
    localparam logic [FUNCT3-1:0] F3_MUL    = 3'b000;
    localparam logic [FUNCT3-1:0] F3_MULH   = 3'b001;
    localparam logic [FUNCT3-1:0] F3_MULHSU = 3'b010;
    localparam logic [FUNCT3-1:0] F3_MULHU  = 3'b011;
    localparam logic [FUNCT3-1:0] F3_DIV    = 3'b100;
    localparam logic [FUNCT3-1:0] F3_DIVU   = 3'b101;
    localparam logic [FUNCT3-1:0] F3_REM    = 3'b110;
    localparam logic [FUNCT3-1:0] F3_REMU   = 3'b111;

    // funct3[2] == 1 -> DIV/REM ailesi (multi-cycle birim secimi icin kisa yol)
    localparam int MD_ISDIV_BIT = 2;

    // =========================================================================
    // SYSTEM  (Zicsr + ayricalikli)
    // =========================================================================
    localparam logic [FUNCT3-1:0] F3_PRIV   = 3'b000;   // ECALL/EBREAK/xRET/WFI
    localparam logic [FUNCT3-1:0] F3_CSRRW  = 3'b001;
    localparam logic [FUNCT3-1:0] F3_CSRRS  = 3'b010;
    localparam logic [FUNCT3-1:0] F3_CSRRC  = 3'b011;
    localparam logic [FUNCT3-1:0] F3_CSRRWI = 3'b101;
    localparam logic [FUNCT3-1:0] F3_CSRRSI = 3'b110;
    localparam logic [FUNCT3-1:0] F3_CSRRCI = 3'b111;

    // funct3[2] == 1 -> immediate formu (uimm[4:0] = instr[19:15])
    localparam int CSR_IMM_BIT = 2;

    // funct12 (instr[31:20]) -- F3_PRIV ile birlikte
    localparam logic [FUNCT12-1:0] SYS_IMM_ECALL  = 12'h000;
    localparam logic [FUNCT12-1:0] SYS_IMM_EBREAK = 12'h001;
    localparam logic [FUNCT12-1:0] SYS_IMM_SRET   = 12'h102;
    localparam logic [FUNCT12-1:0] SYS_IMM_MRET   = 12'h302;
    localparam logic [FUNCT12-1:0] SYS_IMM_WFI    = 12'h105;

    // =========================================================================
    // CSR adresleri
    // =========================================================================
    // ---- Kullanici seviyesi FP CSR'lari (F seti icin ZORUNLU) ----
    localparam logic [CSR_ADDR-1:0] CSR_FFLAGS = 12'h001;
    localparam logic [CSR_ADDR-1:0] CSR_FRM    = 12'h002;
    localparam logic [CSR_ADDR-1:0] CSR_FCSR   = 12'h003;

    // ---- Machine trap setup ----
    localparam logic [CSR_ADDR-1:0] CSR_MSTATUS = 12'h300;
    localparam logic [CSR_ADDR-1:0] CSR_MISA    = 12'h301;
    localparam logic [CSR_ADDR-1:0] CSR_MIE     = 12'h304;
    localparam logic [CSR_ADDR-1:0] CSR_MTVEC   = 12'h305;

    // ---- Machine trap handling ----
    localparam logic [CSR_ADDR-1:0] CSR_MSCRATCH = 12'h340;
    localparam logic [CSR_ADDR-1:0] CSR_MEPC     = 12'h341;
    localparam logic [CSR_ADDR-1:0] CSR_MCAUSE   = 12'h342;
    localparam logic [CSR_ADDR-1:0] CSR_MTVAL    = 12'h343;
    localparam logic [CSR_ADDR-1:0] CSR_MIP      = 12'h344;

    // ---- Machine info (read-only) ----
    localparam logic [CSR_ADDR-1:0] CSR_MVENDORID = 12'hF11;
    localparam logic [CSR_ADDR-1:0] CSR_MARCHID   = 12'hF12;
    localparam logic [CSR_ADDR-1:0] CSR_MIMPID    = 12'hF13;
    localparam logic [CSR_ADDR-1:0] CSR_MHARTID   = 12'hF14;

    // ---- Sayaclar ----
    localparam logic [CSR_ADDR-1:0] CSR_MCYCLE    = 12'hB00;
    localparam logic [CSR_ADDR-1:0] CSR_MINSTRET  = 12'hB02;
    localparam logic [CSR_ADDR-1:0] CSR_MCYCLEH   = 12'hB80;
    localparam logic [CSR_ADDR-1:0] CSR_MINSTRETH = 12'hB82;
    localparam logic [CSR_ADDR-1:0] CSR_CYCLE     = 12'hC00;
    localparam logic [CSR_ADDR-1:0] CSR_TIME      = 12'hC01;
    localparam logic [CSR_ADDR-1:0] CSR_INSTRET   = 12'hC02;
    localparam logic [CSR_ADDR-1:0] CSR_CYCLEH    = 12'hC80;
    localparam logic [CSR_ADDR-1:0] CSR_TIMEH     = 12'hC81;
    localparam logic [CSR_ADDR-1:0] CSR_INSTRETH  = 12'hC82;

    // csr[11:10] == 2'b11 -> read-only (yazma girisimi illegal instruction)
    // csr[9:8]            -> gereken ayricalik seviyesi
    localparam int CSR_RO_MSB   = 11;
    localparam int CSR_RO_LSB   = 10;
    localparam int CSR_PRIV_MSB = 9;
    localparam int CSR_PRIV_LSB = 8;

    // =========================================================================
    // RV32F
    // =========================================================================
    // ---- FLW / FSW funct3 (genislik alani) ----
    localparam logic [FUNCT3-1:0] F3_FLW = 3'b010;   // W = 32-bit
    localparam logic [FUNCT3-1:0] F3_FSW = 3'b010;

    // ---- fmt alani: funct7[1:0] (OP-FP), fused'ta instr[26:25] ----
    localparam logic [1:0] FMT_S = 2'b00;   // single
    localparam logic [1:0] FMT_D = 2'b01;   // double  (RV32D -- desteklenmiyor)
    localparam logic [1:0] FMT_H = 2'b10;
    localparam logic [1:0] FMT_Q = 2'b11;

    // ---- OP-FP funct7 tam degerleri (fmt=S dahil) ----
    localparam logic [FUNCT7-1:0] F7_FADD_S    = 7'b0000000;
    localparam logic [FUNCT7-1:0] F7_FSUB_S    = 7'b0000100;
    localparam logic [FUNCT7-1:0] F7_FMUL_S    = 7'b0001000;
    localparam logic [FUNCT7-1:0] F7_FDIV_S    = 7'b0001100;
    localparam logic [FUNCT7-1:0] F7_FSQRT_S   = 7'b0101100;  // rs2 = 00000
    localparam logic [FUNCT7-1:0] F7_FSGNJ_S   = 7'b0010000;  // funct3: J/JN/JX
    localparam logic [FUNCT7-1:0] F7_FMINMAX_S = 7'b0010100;  // funct3: MIN/MAX
    localparam logic [FUNCT7-1:0] F7_FCMP_S    = 7'b1010000;  // funct3: FLE/FLT/FEQ
    localparam logic [FUNCT7-1:0] F7_FCVT_W_S  = 7'b1100000;  // rs2: W/WU (float->int)
    localparam logic [FUNCT7-1:0] F7_FCVT_S_W  = 7'b1101000;  // rs2: W/WU (int->float)
    localparam logic [FUNCT7-1:0] F7_FMV_X_W   = 7'b1110000;  // f3=000 MV, 001 FCLASS
    localparam logic [FUNCT7-1:0] F7_FMV_W_X   = 7'b1111000;  // f3=000, rs2=00000

    // ---- funct7 = F7_FSGNJ_S ----
    localparam logic [FUNCT3-1:0] F3_FSGNJ  = 3'b000;
    localparam logic [FUNCT3-1:0] F3_FSGNJN = 3'b001;
    localparam logic [FUNCT3-1:0] F3_FSGNJX = 3'b010;

    // ---- funct7 = F7_FMINMAX_S ----
    localparam logic [FUNCT3-1:0] F3_FMIN = 3'b000;
    localparam logic [FUNCT3-1:0] F3_FMAX = 3'b001;

    // ---- funct7 = F7_FCMP_S ----
    localparam logic [FUNCT3-1:0] F3_FLE = 3'b000;
    localparam logic [FUNCT3-1:0] F3_FLT = 3'b001;
    localparam logic [FUNCT3-1:0] F3_FEQ = 3'b010;

    // ---- funct7 = F7_FMV_X_W ----
    localparam logic [FUNCT3-1:0] F3_FMV_X_W = 3'b000;
    localparam logic [FUNCT3-1:0] F3_FCLASS  = 3'b001;

    // ---- rs2 alani, donusum komutlarinin hedef/kaynak tipini secer ----
    localparam logic [REG_ADDR-1:0] RS2_CVT_W  = 5'b00000;  // isaretli
    localparam logic [REG_ADDR-1:0] RS2_CVT_WU = 5'b00001;  // isaretsiz
    localparam logic [REG_ADDR-1:0] RS2_ZERO   = 5'b00000;  // FSQRT/FMV icin zorunlu 0

    // ---- Yuvarlama modlari (funct3 alani, veya frm CSR'i) ----
    localparam logic [2:0] RM_RNE = 3'b000;   // nearest, ties to even
    localparam logic [2:0] RM_RTZ = 3'b001;   // toward zero
    localparam logic [2:0] RM_RDN = 3'b010;   // down (-inf)
    localparam logic [2:0] RM_RUP = 3'b011;   // up   (+inf)
    localparam logic [2:0] RM_RMM = 3'b100;   // nearest, ties to max magnitude
    localparam logic [2:0] RM_DYN = 3'b111;   // dinamik -> frm CSR'inden al
    // NOT: 101 ve 110 rezerve; komutta gorulurse illegal instruction.

    // ---- fflags bit konumlari (fcsr[4:0]) ----
    localparam int FFLAG_NX = 0;   // inexact
    localparam int FFLAG_UF = 1;   // underflow
    localparam int FFLAG_OF = 2;   // overflow
    localparam int FFLAG_DZ = 3;   // divide by zero
    localparam int FFLAG_NV = 4;   // invalid operation

    // ---- IEEE-754 binary32 ----
    localparam int FLEN     = 32;
    localparam int F_EXP_W  = 8;
    localparam int F_MANT_W = 23;
    localparam int F_BIAS   = 127;
    localparam logic [FLEN-1:0] F_CANONICAL_QNAN = 32'h7FC0_0000;

    // =========================================================================
    // RV32C  (16-bit komutlar)
    //   quadrant = instr[1:0],  funct3 = instr[15:13]
    // =========================================================================
    localparam logic [1:0] C_Q0 = 2'b00;
    localparam logic [1:0] C_Q1 = 2'b01;
    localparam logic [1:0] C_Q2 = 2'b10;

    // ---- Quadrant 0 ----
    localparam logic [2:0] C0_ADDI4SPN = 3'b000;
    localparam logic [2:0] C0_FLD      = 3'b001;   // RV32DC -- kullanilmiyor
    localparam logic [2:0] C0_LW       = 3'b010;
    localparam logic [2:0] C0_FLW      = 3'b011;   // RV32FC
    localparam logic [2:0] C0_RESERVED = 3'b100;
    localparam logic [2:0] C0_FSD      = 3'b101;
    localparam logic [2:0] C0_SW       = 3'b110;
    localparam logic [2:0] C0_FSW      = 3'b111;   // RV32FC

    // ---- Quadrant 1 ----
    localparam logic [2:0] C1_ADDI      = 3'b000;  // rd=0 ise C.NOP
    localparam logic [2:0] C1_JAL       = 3'b001;  // RV32 ozel (C.JAL)
    localparam logic [2:0] C1_LI        = 3'b010;
    localparam logic [2:0] C1_LUI_A16SP = 3'b011;  // rd=2 ise ADDI16SP, degilse LUI
    localparam logic [2:0] C1_MISC_ALU  = 3'b100;
    localparam logic [2:0] C1_J         = 3'b101;
    localparam logic [2:0] C1_BEQZ      = 3'b110;
    localparam logic [2:0] C1_BNEZ      = 3'b111;

    // C1_MISC_ALU alt kirilimi: instr[11:10]
    localparam logic [1:0] C1_SRLI  = 2'b00;
    localparam logic [1:0] C1_SRAI  = 2'b01;
    localparam logic [1:0] C1_ANDI  = 2'b10;
    localparam logic [1:0] C1_ARITH = 2'b11;
    // C1_ARITH icinde instr[6:5]  (instr[12]=0 -> RV32 gecerli)
    localparam logic [1:0] C1_SUB = 2'b00;
    localparam logic [1:0] C1_XOR = 2'b01;
    localparam logic [1:0] C1_OR  = 2'b10;
    localparam logic [1:0] C1_AND = 2'b11;

    // ---- Quadrant 2 ----
    localparam logic [2:0] C2_SLLI    = 3'b000;
    localparam logic [2:0] C2_FLDSP   = 3'b001;
    localparam logic [2:0] C2_LWSP    = 3'b010;
    localparam logic [2:0] C2_FLWSP   = 3'b011;   // RV32FC
    localparam logic [2:0] C2_JALR_MV = 3'b100;   // instr[12]: JR/MV vs JALR/ADD
    localparam logic [2:0] C2_FSDSP   = 3'b101;
    localparam logic [2:0] C2_SWSP    = 3'b110;
    localparam logic [2:0] C2_FSWSP   = 3'b111;   // RV32FC

    // RVC sikistirilmis register alani 3-bit -> x8..x15
    localparam logic [1:0] C_REG_PREFIX = 2'b01;  // {2'b01, rs1'} = gercek reg no

    // Tamamen sifir komut (16'h0000) her zaman illegal -- bos bellek yakalama
    localparam logic [15:0] C_ILLEGAL = 16'h0000;

    // =========================================================================
    // Mimari sabitler
    // =========================================================================
    localparam logic [REG_ADDR-1:0] REG_ZERO = 5'd0;
    localparam logic [REG_ADDR-1:0] REG_RA   = 5'd1;   // C.JAL / C.JALR link
    localparam logic [REG_ADDR-1:0] REG_SP   = 5'd2;   // C.ADDI16SP / *SP

    // NOP = ADDI x0, x0, 0
    localparam logic [31:0] INSTR_NOP = 32'h0000_0013;

endpackage
