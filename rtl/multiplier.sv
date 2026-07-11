import riscv_pkg::*;   
module multiplierRTL #(
  parameter int WIDTH   = 32,
  parameter int MUL_LAT = 3
)(
  input  logic             clk_i,
  input  logic             rst_ni,

  input  logic [WIDTH-1:0] rd1_i,
  input  logic [WIDTH-1:0] rd2_i,

  input  mul_alu_e         mode_i,
  input  logic             start_i,        // TEK-cycle darbe
  input  logic             resultHigh_i,   // 1: yüksek yarı (MULH*) , 0: düşük (MUL)

  output logic             done_o,         // TEK-cycle darbe, MUL_LAT cycle sonra
  output logic [WIDTH-1:0] result_o
);

  logic [WIDTH:0] rd1_ext, rd2_ext;
  assign rd1_ext = (mode_i != MULHU)
                 ? {rd1_i[WIDTH-1], rd1_i} : {1'b0, rd1_i};
  assign rd2_ext = (mode_i == MUL || mode_i == MULH)
                 ? {rd2_i[WIDTH-1], rd2_i} : {1'b0, rd2_i};

  // tam çarpım: 2*(WIDTH+1) bit; anlamlı sonuç düşük 2*WIDTH bitte
  logic signed [2*WIDTH+1:0] prod;
  assign prod = $signed(rd1_ext) * $signed(rd2_ext);

  logic [WIDTH-1:0] sel;
  assign sel = resultHigh_i ? prod[2*WIDTH-1:WIDTH] : prod[WIDTH-1:0];

  logic [WIDTH-1:0] r_pipe [0:MUL_LAT-1];
  logic             v_pipe [0:MUL_LAT-1];
  integer i;
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      for (i = 0; i < MUL_LAT; i++) begin
        r_pipe[i] <= '0;
        v_pipe[i] <= 1'b0;
      end
    end else begin
      r_pipe[0] <= sel;          // birleşik çarpma sonucu ilk register'a
      v_pipe[0] <= start_i;
      for (i = 1; i < MUL_LAT; i++) begin
        r_pipe[i] <= r_pipe[i-1];
        v_pipe[i] <= v_pipe[i-1];
      end
    end
  end

  assign result_o = r_pipe[MUL_LAT-1];
  assign done_o   = v_pipe[MUL_LAT-1];

endmodule