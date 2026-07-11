import riscv_pkg::*;
module programCounterRTL(
    input   logic       clk_i,
    input   logic       rst_ni,

    input   logic                   programCounterEn_i,
    input   logic       [WIDTH-1:0] programCounter_i,
    output  logic       [WIDTH-1:0] programCounter_o
);
    always_ff @(posedge clk_i , negedge rst_ni) begin
        if(!rst_ni)begin
            programCounter_o <= 0;
        end else begin
            if(programCounterEn_i)begin
                programCounter_o <= programCounterEn_i;
            end else begin
                programCounter_o <= programCounter_o;
            end
        end
    end
endmodule