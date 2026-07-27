`include "riscv_imports.svh"
// Byte/half/word erisim (little-endian). Load kombinasyonel, store kenarda.
module dataMemRTL (
  input  logic clk_i,
  input  logic [WIDTH-1:0] addr_i,
  input  logic [WIDTH-1:0] wdata_i,
  input  logic             we_i,
  input  logic [2:0]       size_i,      // funct3
  output logic [WIDTH-1:0] rdata_o
);
  localparam int N = DATA_MEM_SIZE/4;
  logic [WIDTH-1:0] mem [0:N-1];
  integer k;
  initial for (k=0;k<N;k++) mem[k] = '0;
  logic [$clog2(N)-1:0] widx;
  logic [1:0]           boff;
  logic [WIDTH-1:0]     word;
  assign widx = addr_i[$clog2(N)+1:2];
  assign boff = addr_i[1:0];
  assign word = mem[widx];
  // load
  logic [7:0]  ld_b; logic [15:0] ld_h;
  assign ld_b = word[boff*8 +: 8];
  assign ld_h = word[boff*8 +: 16];
  always_comb begin
    unique case (size_i)
      3'b000 : rdata_o = {{24{ld_b[7]}},  ld_b};   // LB
      3'b001 : rdata_o = {{16{ld_h[15]}}, ld_h};   // LH
      3'b010 : rdata_o = word;                      // LW
      3'b100 : rdata_o = {24'b0, ld_b};             // LBU
      3'b101 : rdata_o = {16'b0, ld_h};             // LHU
      default: rdata_o = word;
    endcase
  end
  // store
  always_ff @(posedge clk_i) begin
    if (we_i) unique case (size_i)
      3'b000 : mem[widx][boff*8 +: 8]  <= wdata_i[7:0];
      3'b001 : mem[widx][boff*8 +: 16] <= wdata_i[15:0];
      default: mem[widx]               <= wdata_i;   // SW
    endcase
  end
endmodule
