import riscv_pkg::*;
module instructionMemoeyRTL(
    input   logic   [WIDTH-1:0]     address_i,
    output  logic   [WIDTH-1:0]     instructionOut_o
);

    logic [WIDTH-1:0]mem[IMEM_SIZE-1:0];
    initial $readmemh(IMEM, mem);
    assign instructionOut_o = mem[{2'd0 , address_i[31:2]}];
endmodule
