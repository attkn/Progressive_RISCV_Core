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
    
endpackage
