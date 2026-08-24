module coreTopM0(
    input   logic clk_i,
    input   logic rst_ni,

    input   logic [XLEN-1:0]    instructionMemData_i,
    output  logic [XLEN-1:0]    instructionMemAddress_o,

    output  logic [XLEN-1:0]    dataMemAddress_o,
    output  logic               dataMemWrite_o,
    output  logic               dataMemRead_o,
    input   logic [XLEN-1:0]    dataMemoryData_i,       

    output  debug_e debug_o
);  
    

    logic [XLEN-1:0]programCounterOut;
    logic [XLEN-1:0]programCounterIn;

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

    instructionMemory instructionMemory(
        .readAddress_i(programCounterOut),
        .readData_o(instruction)
    );

    assign instruction = instructionMemData_i;
    assign instructionMemAddress_o = programCounterOut;

    logic [OPCODE-1:0]opcode;
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
        .rs3_o(rs3),
        .rd_o(rd),
        .funct7_o(func7),
        .funct3_o(func3),
        .fmt_o(),
        .shift_o(shiftVal),
        .csr_addr_o(),
        .rvc_o()
    );

    logic [XLEN-1:0]imm;

    immGenerator immGenerator(
        .immType_i(), //Control unitle beraber gelecek
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
        .writeData_i(),
        .writeAddress_i(),
        .writeEnable_i(),
        .rd1_o(rd1),
        .rd2_o(rd2)
    );

    alu_op_int_e aluOp;
    logic [XLEN-1:0]aluIntResult;

    aluInt aluInt(
        .aluOp_i(aluOp),
        .rd1_i(rd1),
        .rd2_i(rd2),
        .shift_size(shiftVal),
        .result_o(aluIntResult)
    );

    branch_op_e branchOp;
    logic isBranchTaken;

    aluBranch aluBranch(
        .brOp_i(branchOp),
        .rd1_i(rd1),
        .rd2_i(rd2),
        .branchTaken_o(isBranchTaken)
    );
endmodule