// =============================================================================
//  controlUnit.sv
//  ---------------------------------------------------------------------------
//  RV32I ana dekoder.  M / F / Zicsr dallari illegal olarak isaretli --
//  ilgili birimler eklendikce doldurulacak.
//
//  KRITIK NOT (funct7 kullanimi):
//    funct7 alani SADECE su durumlarda anlamlidir:
//      - OPC_OP     : her zaman
//      - OPC_OP_IMM : sadece shift komutlarinda (SLLI/SRLI/SRAI)
//    Diger OP-IMM komutlarinda instr[31:25] = imm[11:5]'tir. Ornegin
//    ADDI x1,x2,-1 komutunda funct7 = 7'b1111111 olur; buna bakip
//    "SUB" veya "MULDIV" karari vermek DECODE HATASIDIR.
// =============================================================================

module controlUnit  import riscv_opcodes::*, riscv_types::*;(
    input  opcode_e            opcode_i,
    input  logic [FUNCT7-1:0]  funct7_i,
    input  logic [FUNCT3-1:0]  funct3_i,
    input  logic [11:0]        funct12_i,   // ECALL/EBREAK/MRET ayrimi

    output ctrl_t              controlSignals_o,
    output logic               illegalInstr_o
);

    logic isOpImm, isOp, isMulDiv, f7Valid;

    assign isOpImm  = (opcode_i == OPC_OP_IMM);
    assign isOp     = (opcode_i == OPC_OP);
    assign isMulDiv = isOp && (funct7_i == F7_MULDIV);

    // -------------------------------------------------------------------------
    // funct7 gecerlilik kontrolu
    // -------------------------------------------------------------------------
    always_comb begin
        f7Valid = 1'b1;

        if (isOp) begin
            case (funct7_i)
                F7_BASE : f7Valid = 1'b1;
                F7_ALT  : f7Valid = (funct3_i == F3_ADD_SUB) || (funct3_i == F3_SR);
                default : f7Valid = 1'b0;   // MULDIV asagida ayrica ele aliniyor
            endcase
        end
        else if (isOpImm) begin
            case (funct3_i)
                F3_SLL  : f7Valid = (funct7_i == F7_BASE);                         // SLLI
                F3_SR   : f7Valid = (funct7_i == F7_BASE) || (funct7_i == F7_ALT); // SRLI/SRAI
                default : f7Valid = 1'b1;   // funct7 burada imm[11:5], kontrol etme
            endcase
        end
    end

    // -------------------------------------------------------------------------
    // Ana dekoder
    // -------------------------------------------------------------------------
    always_comb begin
        // ================== Varsayilan: NOP (latch onleme) ==================
        controlSignals_o.aluOp               = ALU_ADD;
        controlSignals_o.immType             = IMM_NONE;
        controlSignals_o.isLoadSigned        = 1'b0;
        controlSignals_o.registerFileWriteEn = 1'b0;
        controlSignals_o.immEn               = 1'b0;
        controlSignals_o.loadType            = WORD;
        controlSignals_o.isStoreEn           = 1'b0;
        controlSignals_o.memoryWriteEn       = 1'b0;
        controlSignals_o.storeType           = STORE_WORD;
        controlSignals_o.memoryReadEn        = 1'b0;
        controlSignals_o.isBranchOpRunning   = 1'b0;
        controlSignals_o.aluBranchOp         = ALU_BEQ;
        controlSignals_o.JALen               = 1'b0;
        controlSignals_o.JALRen              = 1'b0;
        controlSignals_o.wbSel               = WB_ALU;
        illegalInstr_o                       = 1'b0;

        case (opcode_i)

        // ============================== LOAD ==============================
        OPC_LOAD: begin
            controlSignals_o.registerFileWriteEn = 1'b1;
            controlSignals_o.memoryReadEn        = 1'b1;
            controlSignals_o.immEn               = 1'b1;
            controlSignals_o.immType             = IMM_I;    // adres = rs1 + I-imm
            controlSignals_o.aluOp               = ALU_ADD;
            controlSignals_o.wbSel               = WB_MEM;

            case (funct3_i)
                F3_LB  : begin controlSignals_o.isLoadSigned = 1'b1; controlSignals_o.loadType = BYTE; end
                F3_LH  : begin controlSignals_o.isLoadSigned = 1'b1; controlSignals_o.loadType = HALF; end
                F3_LW  : begin controlSignals_o.isLoadSigned = 1'b0; controlSignals_o.loadType = WORD; end
                F3_LBU : begin controlSignals_o.isLoadSigned = 1'b0; controlSignals_o.loadType = BYTE; end
                F3_LHU : begin controlSignals_o.isLoadSigned = 1'b0; controlSignals_o.loadType = HALF; end
                default: begin
                    controlSignals_o.registerFileWriteEn = 1'b0;
                    controlSignals_o.memoryReadEn        = 1'b0;
                    illegalInstr_o                       = 1'b1;
                end
            endcase
        end

        // ============================= STORE ==============================
        OPC_STORE: begin
            controlSignals_o.isStoreEn     = 1'b1;
            controlSignals_o.memoryWriteEn = 1'b1;
            controlSignals_o.immEn         = 1'b1;
            controlSignals_o.immType       = IMM_S;          // adres = rs1 + S-imm
            controlSignals_o.aluOp         = ALU_ADD;

            case (funct3_i)
                F3_SB  : controlSignals_o.storeType = STORE_BYTE;
                F3_SH  : controlSignals_o.storeType = STORE_HALF;
                F3_SW  : controlSignals_o.storeType = STORE_WORD;
                default: begin
                    controlSignals_o.isStoreEn     = 1'b0;
                    controlSignals_o.memoryWriteEn = 1'b0;
                    illegalInstr_o                 = 1'b1;
                end
            endcase
        end

        // ========================== OP / OP-IMM ===========================
        OPC_OP_IMM, OPC_OP: begin
            controlSignals_o.registerFileWriteEn = 1'b1;
            controlSignals_o.immEn               = isOpImm;
            controlSignals_o.immType             = isOpImm ? IMM_I : IMM_NONE;
            controlSignals_o.wbSel               = WB_ALU;

            if (isMulDiv) begin
                // ---- RV32M: MUL/MULH/MULHSU/MULHU/DIV/DIVU/REM/REMU ----
                // TODO: multi-cycle birim + stall handshake eklenecek.
                //       funct3_i[MD_ISDIV_BIT] ile MUL/DIV ayrimi yapilabilir.
                controlSignals_o.registerFileWriteEn = 1'b0;
                illegalInstr_o                       = 1'b1;
            end
            else if (!f7Valid) begin
                controlSignals_o.registerFileWriteEn = 1'b0;
                illegalInstr_o                       = 1'b1;
            end
            else begin
                case (funct3_i)
                    // funct7[5] SADECE OPC_OP'ta SUB demektir.
                    F3_ADD_SUB : controlSignals_o.aluOp =
                                    (isOp && funct7_i[F7_ALT_BIT]) ? ALU_SUB : ALU_ADD;
                    F3_SLL     : controlSignals_o.aluOp = ALU_SLL;
                    F3_SLT     : controlSignals_o.aluOp = ALU_SLT;
                    F3_SLTU    : controlSignals_o.aluOp = ALU_SLTU;
                    F3_XOR     : controlSignals_o.aluOp = ALU_XOR;
                    // SRA hem OP hem OP-IMM'de funct7[5] ile ayrilir (f7Valid dogruladi)
                    F3_SR      : controlSignals_o.aluOp =
                                    funct7_i[F7_ALT_BIT] ? ALU_SRA : ALU_SRL;
                    F3_OR      : controlSignals_o.aluOp = ALU_OR;
                    F3_AND     : controlSignals_o.aluOp = ALU_AND;
                    default    : controlSignals_o.aluOp = ALU_ADD;
                endcase
            end
        end

        // =========================== LUI / AUIPC ==========================
        OPC_LUI: begin
            controlSignals_o.registerFileWriteEn = 1'b1;
            controlSignals_o.immEn               = 1'b1;
            controlSignals_o.immType             = IMM_U;
            controlSignals_o.aluOp               = ALU_LUI;   // rd = U-imm
            controlSignals_o.wbSel               = WB_ALU;
        end

        OPC_AUIPC: begin
            controlSignals_o.registerFileWriteEn = 1'b1;
            controlSignals_o.immEn               = 1'b1;
            controlSignals_o.immType             = IMM_U;
            controlSignals_o.aluOp               = ALU_AUIPC; // rd = pc + U-imm
            controlSignals_o.wbSel               = WB_ALU;
        end

        // ============================= BRANCH =============================
        OPC_BRANCH: begin
            controlSignals_o.isBranchOpRunning = 1'b1;
            controlSignals_o.immEn             = 1'b0;   // karsilastirma: rs1 vs rs2
            controlSignals_o.immType           = IMM_B;  // hedef adres: pc + B-imm

            case (funct3_i)
                F3_BEQ  : controlSignals_o.aluBranchOp = ALU_BEQ;
                F3_BNE  : controlSignals_o.aluBranchOp = ALU_BNE;
                F3_BLT  : controlSignals_o.aluBranchOp = ALU_BLT;
                F3_BGE  : controlSignals_o.aluBranchOp = ALU_BGE;
                F3_BLTU : controlSignals_o.aluBranchOp = ALU_BLTU;
                F3_BGEU : controlSignals_o.aluBranchOp = ALU_BGEU;
                default : begin
                    controlSignals_o.isBranchOpRunning = 1'b0;
                    illegalInstr_o                     = 1'b1;
                end
            endcase
        end

        // ============================ JAL / JALR ==========================
        OPC_JAL: begin
            controlSignals_o.registerFileWriteEn = 1'b1;   // rd = pc + 4
            controlSignals_o.JALen               = 1'b1;
            controlSignals_o.immEn               = 1'b1;
            controlSignals_o.immType             = IMM_J;  // hedef: pc + J-imm
            controlSignals_o.wbSel               = WB_PC4;
        end

        OPC_JALR: begin
            if (funct3_i == F3_JALR) begin
                controlSignals_o.registerFileWriteEn = 1'b1;
                controlSignals_o.JALRen              = 1'b1;
                controlSignals_o.immEn               = 1'b1;
                controlSignals_o.immType             = IMM_I;  // (rs1+I-imm) & ~1
                controlSignals_o.aluOp               = ALU_ADD;
                controlSignals_o.wbSel               = WB_PC4;
            end else begin
                illegalInstr_o = 1'b1;
            end
        end

        // ============================= MISC-MEM ===========================
        OPC_MISC_MEM: begin
            // FENCE / FENCE.I : in-order, cache'siz cekirdekte NOP.
            // Cache eklendiginde FENCE.I -> I-cache invalidate + pipeline flush.
            case (funct3_i)
                F3_FENCE, F3_FENCE_I : ; // NOP
                default              : illegalInstr_o = 1'b1;
            endcase
        end

        // ============================== SYSTEM ============================
        OPC_SYSTEM: begin
            case (funct3_i)
                F3_PRIV: begin
                    case (funct12_i)
                        SYS_IMM_ECALL  : ; // TODO: trap -> ecallReq_o
                        SYS_IMM_EBREAK : ; // TODO: trap -> ebreakReq_o
                        default        : illegalInstr_o = 1'b1;  // MRET/WFI sonra
                    endcase
                end
                // TODO Zicsr: csrEn/csrOp sinyalleri ctrl_t'ye eklenecek.
                //   CSRRW/S/C    -> immType = IMM_I  (CSR adresi instr[31:20])
                //   CSRRWI/SI/CI -> immType = IMM_Z  (uimm, SIFIR uzatilir!)
                //   wbSel = WB_CSR
                F3_CSRRW, F3_CSRRS, F3_CSRRC,
                F3_CSRRWI, F3_CSRRSI, F3_CSRRCI : illegalInstr_o = 1'b1;
                default                         : illegalInstr_o = 1'b1;
            endcase
        end

        // ============================== RV32F =============================
        OPC_LOAD_FP, OPC_STORE_FP, OPC_OP_FP,
        OPC_MADD, OPC_MSUB, OPC_NMSUB, OPC_NMADD:
            illegalInstr_o = 1'b1;   // TODO: F seti

        // ============================== CUSTOM ============================
        OPC_CUSTOM_0, OPC_CUSTOM_1, OPC_CUSTOM_2, OPC_CUSTOM_3:
            illegalInstr_o = 1'b1;   // TODO: custom instruction'lar

        default: illegalInstr_o = 1'b1;

        endcase
    end

endmodule
