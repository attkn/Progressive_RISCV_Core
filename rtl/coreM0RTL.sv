// ============================================================================
//  coreM0RTL : M0 single-cycle RV32I + Zicsr cekirdek  (ILK CALISAN CEKIRDEK)
// ----------------------------------------------------------------------------
//  Tek cycle'da: fetch -> decode -> control -> regfile oku -> ALU/branch/mem
//  -> writeback ; PC kenarda guncellenir. Pipeline register YOK (o M2).
//
//  Kapsam: RV32I + Zicsr. Mul/div (multi-cycle) M0'a girmez -> K2/M2'de stall'la.
//
//  Split ALU/branch'in karsiligi burada: BRANCH komutunda ALU hedefi (PC+imm)
//  hesaplarken, branch komparatoru kosulu (rs1 vs rs2) ayni cycle uretir.
// ============================================================================
`include "riscv_imports.svh"

module coreM0RTL (
  input  logic clk_i,
  input  logic rst_ni,
  // --- sentez/debug gozlem portlari ---
  //  Bunlar ic mantigi bir cikisa "capalar". Yoksa cekirdegin hicbir ciktisi
  //  olmadigindan sentez PC/regfile/ALU/bellek dahil HER SEYI olu mantik sayip
  //  siler (util raporu sifir cikar). Gercek FPGA'da bu portlar bir wrapper'a
  //  (LED / UART / AXI) baglanir; simdilik utilization/timing icin yeterli.
  output logic [WIDTH-1:0]      dbg_pc_o,
  output logic [WIDTH-1:0]      dbg_wb_o,
  output logic [RS_ADDRESS-1:0] dbg_rd_o,
  output logic                  dbg_we_o
);

  // ---- fetch ----
  logic [WIDTH-1:0] pc, pc_next, instr;
  pcRTL        u_pc   (.clk_i, .rst_ni, .next_i(pc_next), .pc_o(pc));
  instrMemRTL  u_imem (.addr_i(pc), .instr_o(instr));

  // ---- decode + control ----
  instr_fields_t f;
  ctrl_t         c;
  decoderRTL   u_dec  (.instruction_i(instr), .fields_o(f));
  controlRTL   u_ctl  (.f(f), .ctrl_o(c));

  // ---- register file ----
  logic [WIDTH-1:0] rs1_val, rs2_val, wb_data;
  regFileRTL   u_rf (
    .clk_i, .rst_ni,
    .rs1_addr_i(f.rs1), .rs2_addr_i(f.rs2),
    .rd_addr_i(f.rd),   .rd_wdata_i(wb_data), .rd_we_i(c.wb.reg_write),
    .rs1_val_o(rs1_val), .rs2_val_o(rs2_val)
  );

  // ---- operand mux'lari ----
  logic [WIDTH-1:0] op_a, op_b;
  always_comb begin
    unique case (c.ex.op_a_sel)
      OPA_RS1 : op_a = rs1_val;
      OPA_PC  : op_a = pc;
      OPA_ZERO: op_a = '0;
      default : op_a = rs1_val;
    endcase
    unique case (c.ex.op_b_sel)
      OPB_RS2 : op_b = rs2_val;
      OPB_IMM : op_b = f.imm;
      default : op_b = rs2_val;
    endcase
  end

  // ---- ALU (sonuc: R/I sonucu VEYA branch/jump hedefi = PC+imm / rs1+imm) ----
  logic [WIDTH-1:0] alu_result;
  aluIntRTL #(.WIDTH(WIDTH)) u_alu (
    .aluOp_i(c.ex.alu_op), .rd1_i(op_a), .rd2_i(op_b),
    .shift_size(op_b[5:0]), .result_o(alu_result)
  );

  // ---- branch komparatoru (HAM rs1/rs2) ----
  logic branch_taken;
  aluBranchRTL #(.WIDTH(WIDTH)) u_br (
    .brOp_i(c.ex.br_op), .rd1_i(rs1_val), .rd2_i(rs2_val),
    .branchTaken_o(branch_taken)
  );

  // ---- data memory (adres = ALU sonucu = rs1+imm) ----
  logic [WIDTH-1:0] dmem_rdata;
  dataMemRTL   u_dmem (
    .clk_i, .addr_i(alu_result), .wdata_i(rs2_val),
    .we_i(c.mem.mem_write), .size_i(c.mem.mem_size), .rdata_o(dmem_rdata)
  );

  // ---- CSR (Zicsr) ----
  logic [WIDTH-1:0] csr_rdata, csr_wdata;
  logic             csr_illegal;
  assign csr_wdata = c.ex.csr_use_imm ? f.imm : rs1_val;
  csrFileRTL #(.HART_ID(32'd0)) u_csr (
    .clk_i, .rst_ni,
    .csr_op_i(c.ex.csr_op), .csr_addr_i(f.csr_addr),
    .wdata_i(csr_wdata), .src_is_x0_i(f.rs1 == '0),
    .instret_inc_i(1'b1),                       // M0: her cycle 1 komut retire
    .rdata_o(csr_rdata), .illegal_csr_o(csr_illegal)
  );

  // ---- writeback mux ----
  always_comb begin
    unique case (c.wb.wb_sel)
      WB_ALU : wb_data = alu_result;
      WB_MEM : wb_data = dmem_rdata;
      WB_PC4 : wb_data = pc + 32'd4;
      WB_CSR : wb_data = csr_rdata;
      default: wb_data = alu_result;
    endcase
  end

  // ---- next-PC ----
  //  branch taken -> ALU hedefi (PC+imm) | jump -> hedef (JALR: rs1+imm, bit0=0)
  //  aksi halde PC+4
  always_comb begin
    if (c.ex.is_branch && branch_taken)
      pc_next = alu_result;                                   // dallanma hedefi
    else if (c.ex.is_jump)
      pc_next = (f.opcode == OPC_JALR) ? {alu_result[WIDTH-1:1], 1'b0}
                                       :  alu_result;         // JAL: PC+imm
    else
      pc_next = pc + 32'd4;
  end

  // ---- debug/gozlem ciktilari (sentez capasi) ----
  assign dbg_pc_o = pc;
  assign dbg_wb_o = wb_data;
  assign dbg_rd_o = f.rd;
  assign dbg_we_o = c.wb.reg_write;

endmodule