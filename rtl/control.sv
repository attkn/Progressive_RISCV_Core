// ============================================================================
//  controlRTL : instr_fields_t -> ctrl_t     [ORNEK / ISKELET]
// ----------------------------------------------------------------------------
//  Decoder alanlari TIPLI verdigi icin burada HIC ham bit yok:
//    case (f.opcode)  ->  OPC_OP, OPC_LOAD ...
//    f.funct7         ->  F7_BASE, F7_ALT, F7_MULDIV ...
//    funct3           ->  baglama gore cast: funct3_alu_e'(f.funct3)
//  Bu iskelet I + M kapsar; B/A/C/F ayni desende eklenir.
// ============================================================================
`include "riscv_imports.svh"

module controlRTL (
  input  instr_fields_t f,
  output ctrl_t         ctrl_o
);
  ctrl_t c;
  assign ctrl_o = c;

  always_comb begin
    c = '0;                       // guvenli varsayilan (bubble)
    c.ex.alu_op   = ALU_ADD;
    c.ex.op_a_sel = OPA_RS1;
    c.ex.op_b_sel = OPB_RS2;
    c.ex.unit_sel = UNIT_INT;
    c.illegal     = ~f.opcode_valid;

    unique case (f.opcode)
      // ---------------- R-type: OP ----------------
      OPC_OP: begin
        c.wb.reg_write = 1'b1;  c.wb.wb_sel = WB_ALU;
        if (f.funct7 == F7_MULDIV) begin          // M uzantisi
          unique case (funct3_m_e'(f.funct3))
            F3_MUL   : begin c.ex.unit_sel=UNIT_MUL; c.ex.mul_op=MUL;    end
            F3_MULH  : begin c.ex.unit_sel=UNIT_MUL; c.ex.mul_op=MULH;   end
            F3_MULHSU: begin c.ex.unit_sel=UNIT_MUL; c.ex.mul_op=MULHSU; end
            F3_MULHU : begin c.ex.unit_sel=UNIT_MUL; c.ex.mul_op=MULHU;  end
            F3_DIV   : begin c.ex.unit_sel=UNIT_DIV; c.ex.div_op=DIV;    end
            F3_DIVU  : begin c.ex.unit_sel=UNIT_DIV; c.ex.div_op=DIVU;   end
            F3_REM   : begin c.ex.unit_sel=UNIT_DIV; c.ex.div_op=REM;    end
            F3_REMU  : begin c.ex.unit_sel=UNIT_DIV; c.ex.div_op=REMU;   end
          endcase
        end else begin                             // temel ALU
          unique case (funct3_alu_e'(f.funct3))
            F3_ADD_SUB: if (f.funct7==F7_ALT) c.ex.alu_op=ALU_SUB;
                        else                  c.ex.alu_op=ALU_ADD;
            F3_SLL    : c.ex.alu_op = ALU_SLL;
            F3_SLT    : c.ex.alu_op = ALU_SLT;
            F3_SLTU   : c.ex.alu_op = ALU_SLTU;
            F3_XOR    : c.ex.alu_op = ALU_XOR;
            F3_SR     : if (f.funct7==F7_ALT) c.ex.alu_op=ALU_SRA;
                        else                  c.ex.alu_op=ALU_SRL;
            F3_OR     : c.ex.alu_op = ALU_OR;
            F3_AND    : c.ex.alu_op = ALU_AND;
          endcase
        end
      end
      // ---------------- I-type: OP-IMM ----------------
      OPC_OP_IMM: begin
        c.wb.reg_write=1'b1; c.wb.wb_sel=WB_ALU; c.ex.op_b_sel=OPB_IMM;
        unique case (funct3_alu_e'(f.funct3))
          F3_ADD_SUB: c.ex.alu_op = ALU_ADD;
          F3_SLL    : c.ex.alu_op = ALU_SLL;
          F3_SLT    : c.ex.alu_op = ALU_SLT;
          F3_SLTU   : c.ex.alu_op = ALU_SLTU;
          F3_XOR    : c.ex.alu_op = ALU_XOR;
          F3_SR     : if (f.funct7==F7_ALT) c.ex.alu_op=ALU_SRA;
                      else                  c.ex.alu_op=ALU_SRL;
          F3_OR     : c.ex.alu_op = ALU_OR;
          F3_AND    : c.ex.alu_op = ALU_AND;
        endcase
      end
      // ---------------- LOAD / STORE ----------------
      OPC_LOAD: begin
        c.wb.reg_write=1'b1; c.wb.wb_sel=WB_MEM; c.ex.op_b_sel=OPB_IMM;
        c.ex.unit_sel=UNIT_MEM; c.mem.mem_read=1'b1; c.mem.mem_size=f.funct3;
      end
      OPC_STORE: begin
        c.ex.op_b_sel=OPB_IMM; c.ex.unit_sel=UNIT_MEM;
        c.mem.mem_write=1'b1;  c.mem.mem_size=f.funct3;
      end
      // ---------------- BRANCH / JUMP ----------------
      OPC_BRANCH: begin
        c.ex.unit_sel=UNIT_BRANCH; c.ex.is_branch=1'b1;
        c.ex.br_op = alu_op_branch_e'(f.funct3);     // funct3 == kosul kodu
        c.ex.op_a_sel=OPA_PC; c.ex.op_b_sel=OPB_IMM; // ALU hedefi hesaplar
      end
      OPC_JAL: begin
        c.wb.reg_write=1'b1; c.wb.wb_sel=WB_PC4; c.ex.is_jump=1'b1;
        c.ex.op_a_sel=OPA_PC; c.ex.op_b_sel=OPB_IMM;
      end
      OPC_JALR: begin
        c.wb.reg_write=1'b1; c.wb.wb_sel=WB_PC4; c.ex.is_jump=1'b1;
        c.ex.op_a_sel=OPA_RS1; c.ex.op_b_sel=OPB_IMM;
      end
      // ---------------- LUI / AUIPC ----------------
      OPC_LUI:   begin c.wb.reg_write=1'b1; c.wb.wb_sel=WB_ALU;
                       c.ex.op_a_sel=OPA_ZERO; c.ex.op_b_sel=OPB_IMM; end
      OPC_AUIPC: begin c.wb.reg_write=1'b1; c.wb.wb_sel=WB_ALU;
                       c.ex.op_a_sel=OPA_PC;   c.ex.op_b_sel=OPB_IMM; end
      // ---------------- SYSTEM (Zicsr) ----------------
      OPC_SYSTEM: begin
        c.ex.unit_sel=UNIT_CSR;
        unique case (funct3_sys_e'(f.funct3))
          F3_CSRRW : begin c.ex.csr_op=CSR_OP_RW; c.wb.reg_write=1'b1; c.wb.wb_sel=WB_CSR; end
          F3_CSRRS : begin c.ex.csr_op=CSR_OP_RS; c.wb.reg_write=1'b1; c.wb.wb_sel=WB_CSR; end
          F3_CSRRC : begin c.ex.csr_op=CSR_OP_RC; c.wb.reg_write=1'b1; c.wb.wb_sel=WB_CSR; end
          F3_CSRRWI: begin c.ex.csr_op=CSR_OP_RW; c.ex.csr_use_imm=1'b1; c.wb.reg_write=1'b1; c.wb.wb_sel=WB_CSR; end
          F3_CSRRSI: begin c.ex.csr_op=CSR_OP_RS; c.ex.csr_use_imm=1'b1; c.wb.reg_write=1'b1; c.wb.wb_sel=WB_CSR; end
          F3_CSRRCI: begin c.ex.csr_op=CSR_OP_RC; c.ex.csr_use_imm=1'b1; c.wb.reg_write=1'b1; c.wb.wb_sel=WB_CSR; end
          F3_PRIV  : ;                             // ECALL/EBREAK/MRET
          default  : c.illegal = 1'b1;
        endcase
      end
      OPC_MISC_MEM: ;                              // FENCE / FENCE.I
      default: c.illegal = 1'b1;
    endcase
  end
endmodule
