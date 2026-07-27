`timescale 1ns/1ps
module tb_m0;
  logic clk=0, rst_n=0;
  coreM0RTL dut (.clk_i(clk), .rst_ni(rst_n));
  always #5 clk = ~clk;

  int errors=0, tests=0;
  task automatic chk(input string n, input logic c);
    tests++; if(!c) $display("  FAIL: %s", n); if(!c) errors++;
  endtask

  localparam logic [31:0] MISA_EXP = (32'h1<<30)|(32'h1<<8)|(32'h1<<12); // RV32 I M

  initial begin
    repeat(3) @(posedge clk); rst_n=1;
    // programin bitmesi icin yeterli cycle (dongü ~10 tur + kuyruk)
    repeat(60) @(posedge clk);
    #1;
    $display("=== M0 SONUC ===");
    $display("x1 (sum)  = %0d      (beklenen 55)",  dut.u_rf.regs[1]);
    $display("x2 (i)    = %0d      (beklenen 11)",  dut.u_rf.regs[2]);
    $display("x3 (lim)  = %0d      (beklenen 11)",  dut.u_rf.regs[3]);
    $display("x4 (misa) = %08h (beklenen %08h)", dut.u_rf.regs[4], MISA_EXP);
    $display("mem[0]    = %0d      (beklenen 55)",  dut.u_dmem.mem[0]);
    $display("mem[1]    = %08h (beklenen %08h)", dut.u_dmem.mem[1], MISA_EXP);
    $display("PC        = %08h (0x24'te takili — self-loop)", dut.pc);

    chk("x1=55",        dut.u_rf.regs[1]==32'd55);
    chk("x2=11",        dut.u_rf.regs[2]==32'd11);
    chk("x3=11",        dut.u_rf.regs[3]==32'd11);
    chk("x4=misa",      dut.u_rf.regs[4]==MISA_EXP);
    chk("mem[0]=55",    dut.u_dmem.mem[0]==32'd55);
    chk("mem[4]=misa",  dut.u_dmem.mem[1]==MISA_EXP);
    chk("PC self-loop", dut.pc==32'h0000_0024);

    $display("========================================");
    $display("  %0d tests, %0d errors", tests, errors);
    if(errors==0) $display("  RESULT: ALL PASS  --  ILK PROGRAM KOSTU!");
    else          $display("  RESULT: FAIL");
    $display("========================================");
    $finish;
  end
endmodule
