import riscv_opcodes::*;
import riscv_types::*;

module controlUnit (
    input  opcode_e            opcode_i,
    input  logic [FUNCT7-1:0]  funct7_i,
    input  logic [FUNCT3-1:0]  funct3_i,
    input  logic [11:0]        funct12_i, // ECALL (12'h000) / EBREAK (12'h001) ayrımı için

    output ctrl_t              controlSignals_o
);

    always_comb begin
        // Varsayılan olarak tüm sinyalleri NOP durumuna çek (LATCH önleme)
        controlSignals_o.aluOp = ALU_ADD;
        controlSignals_o.isLoadSigned = 1;
        controlSignals_o.registerFileWriteEn = 0;
        controlSignals_0.immEn = 0;
        controlSignals_o.loadType = BYTE;
        controlSignals_o.memoryWriteEn = 0;
        controlSignals_o.memoryReadEn = 0;
        controlSignals_o.isBranchOpRunning = 0;

        case (opcode_i)
            OPC_LOAD:begin
                controlSignals_o.registerFileWriteEn = 1;
                controlSignals_o.aluOp = ALU_ADD;
                controlSignals_o.registerFileWriteEn = 1;
                controlSignals_0.immEn = 1;
                
                case(funct3_i)
                    F3_LB:begin
                        controlSignals_o.isLoadSigned = 1;
                        controlSignals_o.loadType = BYTE;
                    end

                    F3_LB:begin
                        controlSignals_o.isLoadSigned = 1;
                        controlSignals_o.loadType = HALF;
                    end
                    
                    F3_LBU:begin
                        controlSignals_o.isLoadSigned = 0;
                        controlSignals_o.loadType = BYTE;
                    end

                    F3_LHU:begin
                        controlSignals_o.isLoadSigned = 0;
                        controlSignals_o.loadType = HALF;
                    end

                    default:begin
                        controlSignals_o.isLoadSigned = 0;
                        controlSignals_o.loadType = WORD;
                    end

                endcase
            end

            OPC_OP_IMM , OPC_OP:begin
                controlSignals_o.registerFileWriteEn = 1;
                controlSignals_0.immEn = (opcode_i == OPC_OP_IMM) ?  1 : 0;
                if(!funct7_i[0])begin
                    case(funct3_i)
                    F3_ADD_SUB:begin
                        if(!funct7_i[FUNCT-2])begin
                           controlSignals_o.aluOp = ALU_ADD; 
                        end else begin
                            controlSignals_o.aluOp = ALU_SUB;
                        end
                    end

                    F3_SLL:begin
                        controlSignals_o.aluOp = ALU_SLL;  
                    end

                    F3_SLT:begin
                        controlSignals_o.aluOp = ALU_SLL;  
                    end

                    F3_SLTU:begin
                        controlSignals_o.aluOp = ALU_SLTU;  
                    end

                    F3_XOR:begin
                        controlSignals_o.aluOp = ALU_XOR;  
                    end

                    F3_SR:begin
                        if(!funct7_i[FUNCT-2])begin
                            controlSignals_o.aluOp = ALU_SRL;
                        end else begin
                            controlSignals_o.aluOp = ALU_SRA;   
                        end
                    end
                    
                    F3_OR:begin
                        controlSignals_o.aluOp = ALU_OR;  
                    end

                    F3_AND:begin
                        controlSignals_o.aluOp = ALU_AND;  
                    end

                endcase
                end else begin //Buraya M seti gelecek
                    
                end
            end

            OPC_AUOPC:begin
                controlSignals_o.registerFileWrite = 1;
                controlSignals_o.immEn = 1;
                controlSignals_o.aluOp = ALU_AUIPC;
            end

            OPC_STORE:begin
                controlSignals_o.aluOp = ALU_ADD;
                controlSignals_o.memoryWriteEn = 1;
                controlSignals_o.immEn = 1;
                case(funct3_i)
                    F3_SB:begin
                        controlSignals_o.storeType = BYTE;
                    end

                    F3_SH:begin
                        controlSignals_o.storeType = HALF;
                    end

                    F3_SW:begin
                        controlSignals_o.storeType = WORD;
                    end
                endcase
            end

            OPC_LUI:begin
                controlSignals_o.aluOp = ALU_LUI;
                controlSignals_o.registerFile = 1;
                controlSignals_o.immEn = 1;
            end

            OPC_BRANCH:begin
                controlSignals_o.isBranchOpRunning = 1;
                case(funct3_i)
                    F3_BEQ:begin
                        controlSignals_o.aluOp = ALU_ADD;
                    end
                endcase
            end
        endcase
    end

endmodule