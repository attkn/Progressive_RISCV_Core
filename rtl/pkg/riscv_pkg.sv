package riscv_pkg;
    localparam int unsigned WIDTH = 32;
    localparam int unsigned RS_ADDRESS = 5;
    localparam int          IMEM_SIZE = 4096;
    localparam              IMEM = "imem.mem";
    localparam              DATA_MEM = "memData.mem"
    localparam              DATA_MEM_SIZE = 8192;

    localparam int          ALU_OP_INT = 20;
    localparam int          ALU_OP_MUL = 3;
    localparam int          ALU_OP_DIV = 4;
    localparam int          ALU_OP_BRANCH = 7;
    localparam int          MUL_LAT = 3;


    localparam              ISA_I       =   40;
    localparam              ISA_M       =   8;
    localparam              ISA_CSR     =   6; 
    localparam              ISA_FENCE   =   1;
    localparam              ISA_A       =   11;
    localparam              ISA_C       =   29;
    localparam              ISA_B       =   29;
    localparam              ISA_BC      =   3;
    localparam              ISA_F       =   26;
//    localparam              ISA_V       =  



    typedef enum logic [2:0] { 
        IMM_I, 
        IMM_S, 
        IMM_B, 
        IMM_U, 
        IMM_J, 
        IMM_Z } imm_sel_e;

    typedef enum logic [$clog2(ALU_OP_INT):2] {
        ADD,
        SUB
    } alu_op_int_e;    


    /*
            MULTIPLIER COMMANDS
    ==================================
            rd1         rd2
        0 = signed      signed
        1 = signed      unsigned
        2 = unsigned    unsigned 
    ==================================       
    */
    typedef enum logic [$clog2(ALU_OP_MUL)-1:0]{
        MUL
    }alu_op_mul_e;

    /*
            MULTIPLIER COMMANDS
    ==================================
            rd1             rd2
        0 = signed-div      signed-div
        1 = unsigned-div    unsigned-div
        2 = signed-rem      signed-rem
        3 = unsigned-rem    signed-rem
    ==================================       
    */
    typedef enum logic [$clog2(ALU_OP_DIV)-1:0]{
        DIV
    }alu_op_div_e;

    typedef enum logic [$clog2(ALU_OP_BRANCH)-1:0]{
        B
    }alu_op_branch_e;
    
    typedef enum logic [$clog2(ISA_I)-1:0] {
        LUI,
        AUIPC,
        JAL,
        JALR,
        BEQ,
        BNE,
        BLT,
        BLTU,
        LB,
        LH,
        LW,
        LBU,
        LHU,
        SB,
        SH,
        SW,
        ADDI,
        SLTI,
        SLTIU,
        XORI,
        ORI,
        ANDI,
        SLLI,
        SRLI,
        SRAI,
        ADD,
        SUB,
        SLL,
        SLT,
        SLTU,
        XOR,
        SRL,
        SRA,
        OR,
        AND,
        FENCE,
        ECALL,
        EBREAK
    }isa_i;


    typedef enum logic [$clog2(ISA_CSR)-1:0] {
        CSRRW,
        CSRRS,
        CSRRC,
        CSRRWI,
        CSRRSI,
        CSRRCI,
        FENCEI
    }isa_csr;

    typedef enum logic [$clog2(ISA_M)-1:0] {
        MUL,MULH,MULHSU,MULHU,
        DIV,DIVU,
        REM,REMU
    }isa_m;

    typedef enum logic [$clog2(ISA_A)-1:0] {
        LRW,SCW,
        AMOSWAPW,AMOADDW,AMOXORW,AMOANDW,AMOORW,
        AMOMINW,AMOMAXW,AMOMINU,AMOMAXUW
    }isa_a;

    typedef enum logic [$clog2(ISA_C)-1:0] {
        CADDI4SPN,
        CLW,CSW,CFLW,CFSW,
        CNOP_CADDI,
        CJAL,
        CLI,
        CLUI_CADDI16SP,
        CSRLI,
        CSRAI,
        CANDI,
        CSUB,
        CXOR,
        COR,
        CAND,
        CJ,
        CBEQZ
        CBNEZ,
        CSLLI,
        CLWSP,
        CFLWSP,CJR,CMV,CEBREAK,
        CJALR,CADD,
        CSWSP,CFSWSP
    }isa_c;
endpackage
