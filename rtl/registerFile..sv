`include "riscv_include.svh"
module registerFile(
    input   logic       clk_i,
    input   logic       rst_ni,

    input   logic   [RS-1:0]    rs1_i,
    input   logic   [RS-1:0]    rs2_i,
    input   logic   [XLEN-1:0]  writeData_i,
    input   logic   [RS-1:0]    writeAddress_i,
    input   logic               writeEnable_i,

    output  logic   [XLEN-1:0]  rd1_o,
    output  logic   [XLEN-1:0]  rd2_o
);
    logic [XLEN-1:0]mem[XLEN-1:0];

    always_ff @(negedge clk_i , posedge rst_ni)begin
        if(rst_ni)begin
            $readmemh("registerFile.mem" , mem);
        end else begin
            if(writeEnable_i)begin
                mem[writeAddress_i] <= writeData_i;
            end
        end
    end

    assign rd1_o = mem[rs1_i];
    assign rd2_o = mem[rs2_i];

endmodule