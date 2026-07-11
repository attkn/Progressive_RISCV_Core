import riscv_pkg::*;
module programCounterAdderRTL(
    input   logic   [WIDTH-1:0]in_i,
    input   logic   [WIDTH-1:0]out_o 
);
    assign out_o = in_i + 1;
endmodule