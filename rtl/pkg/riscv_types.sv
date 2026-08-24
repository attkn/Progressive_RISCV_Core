// ============================================================================
//  riscv_types.sv
//  Mikromimari tipleri. ISA encoding'i BILMEZ (o riscv_opcodes'ta).
//  Pipeline derinlestikce / yeni birim ekledikce burasi buyur.
// ============================================================================
import riscv_opcodes::*;
package riscv_types;

    localparam int unsigned XLEN   = 32;
    localparam int unsigned ILEN   = 32;
    localparam int unsigned RS     = 5;
    localparam int unsigned SHIFT  = 5;
    localparam int unsigned OPCODE = 7;
    localparam int unsigned FUNCT7 = 7;   // <-- eski kodda FUNC7/FUNCT7 karisikti
    localparam int unsigned FUNCT3 = 3;
    localparam int unsigned CSR_W  = 12;
    localparam int unsigned ALU_I_OP = 12
    localparam int unsigned ALU_BRANCH_OP = 7

    localparam logic [XLEN-1:0] PC_DEFAULT = '0;

    // ------------------------------------------------------------------
    // Immediate formati (seninki, aynen korundu)
    // ------------------------------------------------------------------
    typedef enum logic [2:0] {
        I_TYPE = 3'b000,
        S_TYPE = 3'b001,
        B_TYPE = 3'b010,
        U_TYPE = 3'b011,
        J_TYPE = 3'b100,
        Z_TYPE = 3'b101,   // CSR uimm
        NO_IMM = 3'b111
    } immType_e;

    typedef enum logic [$clog2(ALU_I_OP)-1:0] {
        ALU_ADD,
        ALU_SUB,
        ALU_AND,
        ALU_OR,
        ALU_XOR,
        ALU_SLL,
        ALU_SRL,
        ALU_SRA,
        ALU_SLT,
        ALU_SLTU,
        ALU_AUIPC,
        ALU_LUI
    } aluOpInt_e;

    typedef enum logic [$clog2(ALU_BRANCH_OP)-1:0] {
        ALU_ADD,
        ALU_SUB,
        ALU_AND,
        ALU_OR,
        ALU_XOR,
        ALU_SLL,
        ALU_SRL,
        ALU_SRA,
        ALU_SLT,
        ALU_SLTU,
        ALU_AUIPC,
        ALU_LUI
    } aluOpBranch_e;

    typedef enum logic [1:0] { 
        BYTE,
        HALF,
        WORD
    } loadType_e;

    typedef enum logic [1:0] { 
        BYTE,
        HALF,
        WORD
    } storeType_e;

    typedef struct packed {
        aluOpInt_e aluOp;
        logic isLoadSigned;
        logic registerFileWriteEn;
        logic immEn;
        loadType_e loadType;
        logic memoryWriteEn;
        storeStype_e storeType;
        logic memoryReadEn;
        logic isBranchOpRunning;
        aluOpBranch_e aluBranchOp
    } ctrl_t; 

endpackage
