module coreTopM0 import riscv_opcodes::*, riscv_types::*; (
    input   logic clk_i,
    input   logic rst_ni,

    input   logic [XLEN-1:0]    instructionMemData_i,
    output  logic [XLEN-1:0]    instructionMemAddress_o,

    output  logic [XLEN-1:0]    dataMemAddress_o,

    output  logic [XLEN-1:0]    dataMemWriteData_o,
    output  logic               dataMemWriteDataEn_o,

    input  logic  [XLEN-1:0]    dataMemReadData_o,
    output  logic               dataMemReadDataEn_o
);  
    

    logic [XLEN-1:0]programCounterOut;
    logic [XLEN-1:0]programCounterIn;

    logic [XLEN-1:0] registerFileWriteData;

    programCounter programCounter(
        .clk_i(clk_i),
        .rst_ni(rst_ni),
        .stall_i(stallProgramCounter),
        .programCounter_i(programCounterIn),
        .programCounter_o(programCounterOut)
    );

    //Increasing program counter
    logic [XLEN-1:0] pcIncreasedFour;
    assign pcIncreasedFour = programCounterOut + 32'd4;

    logic [XLEN-1:0]instruction;
    assign instructionMemAddress_o = programCounterOut;
    assign instruction = instructionMemData_i;

    assign instruction = instructionMemData_i;
    assign instructionMemAddress_o = programCounterOut;

    opcode_e opcode;
    logic [RS-1:0]rs1;
    logic [RS-1:0]rs2;
    logic [RS-1:0]rs3;
    logic [RS-1:0]rd;

    logic [FUNC7-1:0]func7;
    logic [FUNC3-1:0]func3;

    logic [SHIFT-1:0]shiftVal;

    decoder decoder(
        .instruction_i(instruction),
        .opcode_o(opcode),
        .rs1_o(rs1),
        .rs2_o(rs2),
        //.rs3_o(rs3),
        .rd_o(rd),
        .funct7_o(func7),
        .funct3_o(func3),
        //.fmt_o(),
        .shift_o(shiftVal)
        //.csr_addr_o(),
        //.rvc_o()
    );

    ctrl_t controlSignals;
    logic illegalInstr;

    controlUnit controlUnit(
        .opcode_i(opcode),
        .funct3_i(funct3),
        .funct7_i(funct7),
        .funct12_i(),

        .controlSignals_o(controlSignals),
        .illegalInstr_o(illegalInstr)
    );



    logic [XLEN-1:0]imm;

    immGenerator immGenerator(
        .immType_i(controlSignals.immType), //Control unitle beraber gelecek
        .instr_i(instruction),
        .imm_o(imm)
    );

    //Branch Adder
    logic branchAddress = imm + programCounterOut;

    logic [XLEN-1:0]rd1;
    logic [XLEN-1:0]rd2;
    registerFile registerFile(
        .clk_i(clk_i),
        .rst_ni(rst_ni),
        .rs1_i(rs1),
        .rs2_i(rs2),
        .writeData_i(registerFileWriteData),
        .writeAddress_i(rd),
        .writeEnable_i(controlSignals.registerFileWriteEn),
        .rd1_o(rd1),
        .rd2_o(rd2)
    );

    aluOpInt_e aluOp;
    logic [XLEN-1:0]aluIntResult;

    logic [XLEN-1:0] aluIn1;
    logic [XLEN-1:0] aluIn2;

    logic [XLEN-1:0] storeRD2;
    assign aluIn1 = rd1;



    always_comb begin: RD2_MUX
        if(controlSignals.isStoreEn)begin 
            if(controlSignals.storeType == STORE_BYTE)begin
                storeRD2 = {rd2[7:0]};
            end else begin
                if(controlSignals.storeType == STORE_HALF)begin
                    storeRD2 = {rd2[15:0]};
                end else begin
                    storeRD2 = rd2;
                end
            end
        end else begin
            
        end

        if(controlSignals.immEn)begin 
            aluIn2 = imm;  
        end else begin
            aluIn2 = storeRD2;
        end
    end

    aluInt aluInt(
        .aluOp_i(aluOp),
        .rd1_i(rd1),
        .rd2_i(rd2),
        .shift_size(shiftVal),
        .result_o(aluIntResult)
    );

    aluOpBranch_e branchOp;
    logic isBranchTaken;

    aluBranch aluBranch(
        .brOp_i(branchOp),
        .rd1_i(rd1),
        .rd2_i(rd2),
        .branchTaken_o(isBranchTaken)
    );

    assign dataMemReadEn_o  = controlSignals.memoryReadEn;
    assign dataMemWriteEn_o = controlSignals.memoryWriteEn;
    assign dataMemWriteData_o = aluIntResult;
    assign dataMemAddress_o = aluIntResult;

    always_comb begin : RegisterFile_Write_Mux
        case({controlSignals.JALen || controlSignals.JALRen , controlSignals.memoryReadEn})
            2'b001: begin registerFileWriteData = dataMemReadData_o; end
            2'b010: begin registerFileWriteData = pcIncreasedFour; end
            default:begin registerFileWriteData = aluIntResult; end                  
        endcase
    end
    
    always_comb begin : ProgramCounter_Mux
        case({controlSignals.isBranchOpRunning , controlSignals.JALRen , controlSignals.JALen })
            3'b100:begin 
                if(isBranchTaken)begin
                    programCounterIn = branchAddress;
                end else begin
                    programCounterIn = pcIncreasedFour;
                end
            end
            3'b010:begin 
                programCounterIn = aluIntResult || {{31{1'b1}} , 1'b0};
            end
            3'b001:begin 
                programCounterIn = aluIntResult;
            end
            default:begin 
                programCounterIn = pcIncreasedFour;
            end
        endcase 
    end
endmodule