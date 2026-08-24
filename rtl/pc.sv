module programCounter(
    input   logic       clk_i,
    input   logic       rst_ni,

    input   logic       stall_i

    input   logic       programCounter_i,
    output  logic       programCounter_o
);
    always_ff @(posedge clk_i , negedge rst_ni)begin
        if(!rst_ni)begin
            programCounter <= PC_DEFAULT;
        end else begin
            programCounter_o <= programCounter_i; 
        end
    end
endmodule