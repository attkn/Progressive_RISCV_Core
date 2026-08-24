module programCounter import riscv_opcodes::*, riscv_types::*;(
    input   logic       clk_i,
    input   logic       rst_ni,

    input   logic       stall_i,

    input   logic       programCounter_i,
    output  logic       programCounter_o
);
    always_ff @(posedge clk_i , negedge rst_ni)begin
        if(!rst_ni)begin
            programCounter_o <= PC_DEFAULT;
        end else begin
            programCounter_o <= programCounter_i; 
        end
    end
endmodule