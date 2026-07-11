module generalPurposeRegisterFileRTL #(
    parameter GPR_ADDRESS_WIDTH = 5,
    parameter DATA_WIDHT = 32
    )(
    input logic                                 clk_i,
    input logic                                 rst_ni,

    input logic     [GPR_ADDRESS_WIDTH-1:0]     gprAddress1_i,
    input logic     [GPR_ADDRESS_WIDTH-1:0]     gprAddress2_i,

    input logic                                 writeGprEn_i,
    input logic                                 writeGprData_i,
    input logic                                 writeGprAddress_i,

    output logic    [DATA_WIDHT-1:0]            gprData1_o,
    output logic    [DATA_WIDHT-1:0]            gprData2_o
);
    logic [DATA_WIDHT-1:0]register[DATA_WIDHT-1:0];

    always_ff @(posedge clk_i , negedge rst_ni)begin
        if(!rst_ni)begin
            register <= '{default: 0};
        end else begin
            if(writeGprEn_i)begin
                register[writeGprAddress_i] <= writeGprData_i;
            end else begin
                register <= register;
            end
        end
    end


    assign gprData1_o = register[gprAddress1_i];
    assign gprData2_o = register[gprAddress2_i];
endmodule