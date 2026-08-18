`timescale 1ns / 1ps

module divUnitRTL (
    input  logic        clk_i,
    input  logic        rst_ni,

    input  logic        flush_i,
    input  logic        mode_i,
    input  logic        start_i,
    
    input  logic [31:0] dividend_i,
    input  logic [31:0] divisor_i,
    
    output logic [31:0] quotient_o,
    output logic [31:0] remainder_o,
    
    output logic        done_o
);

    typedef enum logic [1:0] {
        STATE_IDLE = 2'b00,
        STATE_CALC = 2'b01,
        STATE_DONE = 2'b10
    } state_t;

    state_t currentState, nextState;

    logic [32:0] aReg;
    logic [31:0] qReg;
    logic [31:0] mReg;
    logic [5:0]  counter;

    logic        signQuotientReg;
    logic        signRemainderReg;
    logic [31:0] dividendSavedReg;
    logic        isDivByZeroReg;
    logic        isOverflowReg;

    logic [31:0] dividendMag;
    logic [31:0] divisorMag;
    logic        dividendSign;
    logic        divisorSign;

    logic        isDivByZero;
    logic        isOverflow;

    assign isDivByZero  = (divisor_i == 32'd0);
    assign isOverflow   = (!mode_i) && (dividend_i == 32'h8000_0000) && (divisor_i == 32'hFFFF_FFFF);

    assign dividendSign = (!mode_i) ? dividend_i[31] : 1'b0;
    assign divisorSign  = (!mode_i) ? divisor_i[31]  : 1'b0;

    assign dividendMag  = (dividendSign) ? (-dividend_i) : dividend_i;
    assign divisorMag   = (divisorSign)  ? (-divisor_i)  : divisor_i;

    logic [32:0] shiftedAcc;
    logic [32:0] subResult;

    assign shiftedAcc = {aReg[31:0], qReg[31]};
    assign subResult  = shiftedAcc - {1'b0, mReg};

    always_comb begin
        nextState = currentState;

        case (currentState)
            STATE_IDLE: begin
                if (start_i) begin
                    if (isDivByZero || isOverflow) begin
                        nextState = STATE_DONE;
                    end else begin
                        nextState = STATE_CALC;
                    end
                end
            end

            STATE_CALC: begin
                if (counter == 6'd31) begin
                    nextState = STATE_DONE;
                end
            end

            STATE_DONE: begin
                nextState = STATE_IDLE;
            end

            default: nextState = STATE_IDLE;
        endcase
    end

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            currentState     <= STATE_IDLE;
            aReg             <= '0;
            qReg             <= '0;
            mReg             <= '0;
            counter          <= '0;
            signQuotientReg  <= 1'b0;
            signRemainderReg <= 1'b0;
            dividendSavedReg <= '0;
            isDivByZeroReg   <= 1'b0;
            isOverflowReg    <= 1'b0;
            quotient_o       <= '0;
            remainder_o      <= '0;
            done_o           <= 1'b0;
        end else if (flush_i) begin
            currentState     <= STATE_IDLE;
            aReg             <= '0;
            qReg             <= '0;
            mReg             <= '0;
            counter          <= '0;
            isDivByZeroReg   <= 1'b0;
            isOverflowReg    <= 1'b0;
            done_o           <= 1'b0;
        end else begin
            currentState <= nextState;
            done_o       <= 1'b0;

            case (currentState)
                STATE_IDLE: begin
                    if (start_i) begin
                        dividendSavedReg <= dividend_i;
                        isDivByZeroReg   <= isDivByZero;
                        isOverflowReg    <= isOverflow;

                        aReg             <= 33'd0;
                        qReg             <= dividendMag;
                        mReg             <= divisorMag;
                        counter          <= 6'd0;
                        signQuotientReg  <= dividendSign ^ divisorSign;
                        signRemainderReg <= dividendSign;
                    end
                end

                STATE_CALC: begin
                    counter <= counter + 1'b1;

                    if (subResult[32]) begin
                        aReg <= shiftedAcc;
                        qReg <= {qReg[30:0], 1'b0};
                    end else begin
                        aReg <= subResult;
                        qReg <= {qReg[30:0], 1'b1};
                    end
                end

                STATE_DONE: begin
                    done_o <= 1'b1;

                    if (isDivByZeroReg) begin
                        quotient_o  <= 32'hFFFF_FFFF;
                        remainder_o <= dividendSavedReg;
                    end else if (isOverflowReg) begin
                        quotient_o  <= 32'h8000_0000;
                        remainder_o <= 32'h0000_0000;
                    end else begin
                        quotient_o  <= (signQuotientReg)  ? (-qReg)       : qReg;
                        remainder_o <= (signRemainderReg) ? (-aReg[31:0]) : aReg[31:0];
                    end
                end

                default: ;
            endcase
        end
    end

endmodule
