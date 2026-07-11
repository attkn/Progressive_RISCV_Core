import riscv_pkg::*;

module imm_gen (
  input  logic [31:0] immediate_i,
  input  imm_sel_e    immediateType_i,     // decode'dan gelir
  output logic [31:0] immediateGenerated_o
);
  always_comb begin
    unique case (immediateType_i)
      IMM_I: begin
        immediateGenerated_o = {{20{immediate_i[31]}}, immediate_i[31:20]};
      end
      IMM_S: begin
        immediateGenerated_o = {{20{immediate_i[31]}}, immediate_i[31:25], immediate_i[11:7]};
      end
      IMM_B: begin
        immediateGenerated_o = {{19{immediate_i[31]}}, immediate_i[31], immediate_i[7],
                     immediate_i[30:25], immediate_i[11:8], 1'b0};
      end
      IMM_U: begin
        immediateGenerated_o = {immediate_i[31:12], 12'b0};
      end
      IMM_J: begin
        immediateGenerated_o = {{11{immediate_i[31]}}, immediate_i[31], immediate_i[19:12],
                     immediate_i[20], immediate_i[30:21], 1'b0};
      end
      IMM_Z: begin 
        immediateGenerated_o = {27'b0, immediate_i[19:15]};
      end
      default: begin
        immediateGenerated_o = '0;                          
      end
    endcase
  end
endmodule