`include "riscv_imports.svh"
// Komut bellegi. Mem dosyasi yolu build sistemi tarafindan verilebilir:
//   iverilog / varsayilan -> "imem.mem" (cwd'den, sw/ icinden kosulur)
//   Vivado xsim           -> -d IMEM_FILE="/mutlak/yol/imem.mem" (sim dizini derdi yok)
`ifndef IMEM_FILE
  `define IMEM_FILE "imem.mem"
`endif
module instrMemRTL (
  input  logic [WIDTH-1:0] addr_i,
  output logic [WIDTH-1:0] instr_o
);
  logic [WIDTH-1:0] mem [0:(IMEM_SIZE/4)-1];
  initial $readmemh(`IMEM_FILE, mem);
  assign instr_o = mem[addr_i[$clog2(IMEM_SIZE)-1:2]];
endmodule
