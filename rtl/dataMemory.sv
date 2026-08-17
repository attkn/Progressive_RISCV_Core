module dataMemoryRTL (
    input logic clk_i,
    input logic rst_ni,
    
    input logic [XLEN-1:0] writeAddress_i,
    input logic [XLEN-1:0] writeData_i,
    input logic writeEnable_i,

    input logic [XLEN-1:0] readAddress_i,
    input logic readEnable_i,
    output logic [XLEN-1:0] readData_o

);
    logic [XLEN-1:0]mem[DATA_MEM_LENGTH-1:0];

    always_ff @(posedge clk_i)begin
        if(!rst_ni)begin
            $readmemh("dataMemory.mem" , mem);
        end else begin
            if(writeEnable_i)begin
                mem[writeAddress_i] <= writeData_i;
            end

            if(readEnable_i)begin
                readData_o <= mem[readAddress_i];
            end
        end
    end
endmodule