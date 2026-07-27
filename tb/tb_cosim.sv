`timescale 1ns/1ps
`ifndef NUM
 `define NUM 40
`endif
module tb_cosim;
  logic clk=0, rst_n=0;
  coreM0RTL dut (.clk_i(clk), .rst_ni(rst_n));
  always #5 clk = ~clk;

  integer fh, n;
  logic [4:0]  rd_eff;
  logic [31:0] rdv, maddr, mdata;
  logic [2:0]  sz;

  initial begin
    fh = $fopen("rtl_trace.log", "w");
    rst_n = 0; repeat(3) @(posedge clk);
    @(negedge clk); rst_n = 1;              // reset'i kenardan uzakta birak (race yok)
    // her cycle mid-point'te o cycle'da yurutulen komutu logla (ilk: pc=0)
    for (n = 0; n < `NUM; n++) begin
      #1;
      rd_eff = (dut.c.wb.reg_write && (dut.f.rd != 5'd0)) ? dut.f.rd : 5'd0;
      rdv    = (rd_eff != 5'd0) ? dut.wb_data : 32'd0;
      maddr  = dut.c.mem.mem_write ? dut.alu_result : 32'd0;
      mdata  = dut.c.mem.mem_write ? dut.rs2_val    : 32'd0;
      sz     = dut.c.mem.mem_write ? dut.c.mem.mem_size : 3'd0;
      $fwrite(fh, "%08x %0d %08x %0d %08x %08x %0d\n",
              dut.pc, rd_eff, rdv, dut.c.mem.mem_write, maddr, mdata, sz);
      @(negedge clk);
    end
    $fclose(fh);
    $display("RTL trace: %0d komut -> rtl_trace.log", `NUM);
    $finish;
  end
endmodule
