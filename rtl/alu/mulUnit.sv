module mulTopRTL #(
    parameter XLEN = 32
)(
    input   logic [XLEN-1:0]      in0_i,
    input   logic [XLEN-1:0]      in1_i,
    input   logic                 mode_i,
    output  logic [2*XLEN-1:0]    result_o

);

    logic signed [XLEN:0] signed_in0;
    logic signed [XLEN:0] signed_in1;

    always_comb begin
        
        
        result_o = signed_in0 * signed_in1;
    end

endmodule