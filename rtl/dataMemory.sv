import riscv_pgk::*;

module dataMemoryRTL(
    input   logic   clk_i,
    input   logic   rst_ni,

    input   logic   [WIDTH-1:0]address_i,
    input   logic   data_i,
    input   logic   writeEn_i,
    input   logic   readEn_i,

    output  logic   [WIDTH-1:0]data_o 

);
    logic [WIDTH-1:0]mem[DATA_MEM_SIZE:0];
    initial $readmemh(MEM_DATA , mem);

    always_ff @(posedge clk_i , negedge rst_ni)begin
        if(!rst_ni)begin
            mem <= '{default:0};
        end else begin
            if(dataWrite_i)begin
                mem[address_i] <= data_i;
            end else begin
                mem <= mem;
            end
        end
    end

    assign data_o = (readEn_i) ? mem[address_i] : 0;
endmodule