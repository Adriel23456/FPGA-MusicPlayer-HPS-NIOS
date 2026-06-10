// AudioBiquadFilter.sv
// 01 = biquad low-pass, 10 = biquad band-pass, 11 = reverb (feedback comb
// echo, BRAM delay line), 00 = registered bypass (the I2S wrapper also has
// a hard serial bypass for 00).

module AudioBiquadFilter #(
    parameter int DATA_WIDTH  = 16,
    parameter int COEF_WIDTH  = 18,
    parameter int COEF_FRAC   = 14,
    parameter int REVERB_ADDR = 11,     // 2^11 = 2048-sample delay line
    parameter int REVERB_DLY  = 1800    // echo delay (~150 ms @ 12 kHz DAC)
) (
    input  logic clk,                   // BCLK
    input  logic reset_reset_n,
    input  logic [1:0] filter_mode,
    input  logic sample_valid,
    input  logic signed [DATA_WIDTH-1:0] sample_left_in,
    input  logic signed [DATA_WIDTH-1:0] sample_right_in,
    output logic sample_ready,
    output logic sample_valid_out,
    output logic signed [DATA_WIDTH-1:0] sample_left_out,
    output logic signed [DATA_WIDTH-1:0] sample_right_out
);
    // ── Coefficients (Q14) ───────────────────────────────────────
    localparam logic signed [COEF_WIDTH-1:0] LP_B0 =  18'sd1105;
    localparam logic signed [COEF_WIDTH-1:0] LP_B1 =  18'sd2210;
    localparam logic signed [COEF_WIDTH-1:0] LP_B2 =  18'sd1105;
    localparam logic signed [COEF_WIDTH-1:0] LP_A1 = -18'sd18726;
    localparam logic signed [COEF_WIDTH-1:0] LP_A2 =  18'sd6768;

    localparam logic signed [COEF_WIDTH-1:0] BP_B0 =  18'sd3385;
    localparam logic signed [COEF_WIDTH-1:0] BP_B1 =  18'sd0;
    localparam logic signed [COEF_WIDTH-1:0] BP_B2 = -18'sd3385;
    localparam logic signed [COEF_WIDTH-1:0] BP_A1 = -18'sd6058;
    localparam logic signed [COEF_WIDTH-1:0] BP_A2 =  18'sd9604;

    localparam logic signed [COEF_WIDTH-1:0] RV_G  =  18'sd9011;  // 0.55 feedback

    localparam logic signed [DATA_WIDTH-1:0] SMAX = {1'b0, {(DATA_WIDTH-1){1'b1}}};
    localparam logic signed [DATA_WIDTH-1:0] SMIN = {1'b1, {(DATA_WIDTH-1){1'b0}}};

    function automatic logic signed [DATA_WIDTH-1:0] sat(input logic signed [63:0] v);
        if      (v > longint'(SMAX)) sat = SMAX;
        else if (v < longint'(SMIN)) sat = SMIN;
        else                         sat = v[DATA_WIDTH-1:0];
    endfunction

    assign sample_ready = 1'b1;

    // ── Biquad state + coefficient mux ───────────────────────────
    logic signed [DATA_WIDTH-1:0] x1l, x2l, y1l, y2l, x1r, x2r, y1r, y2r;
    logic [1:0] mode_q;
    logic signed [COEF_WIDTH-1:0] b0, b1, b2, a1, a2;

    always_comb begin
        unique case (filter_mode)
            2'b01:   begin b0=LP_B0; b1=LP_B1; b2=LP_B2; a1=LP_A1; a2=LP_A2; end
            2'b10:   begin b0=BP_B0; b1=BP_B1; b2=BP_B2; a1=BP_A1; a2=BP_A2; end
            default: begin b0='0; b1='0; b2='0; a1='0; a2='0; end
        endcase
    end

    logic signed [63:0] acc_l, acc_r;
    always_comb begin
        acc_l = (b0 * sample_left_in)  + (b1 * x1l) + (b2 * x2l)
              - (a1 * y1l)             - (a2 * y2l);
        acc_r = (b0 * sample_right_in) + (b1 * x1r) + (b2 * x2r)
              - (a1 * y1r)             - (a2 * y2r);
    end
    wire signed [DATA_WIDTH-1:0] bq_l = sat(acc_l >>> COEF_FRAC);
    wire signed [DATA_WIDTH-1:0] bq_r = sat(acc_r >>> COEF_FRAC);

    // ── Reverb: y[n] = sat(x[n] + g·y[n-D]), BRAM delay line ─────
    localparam int RV_DEPTH = 1 << REVERB_ADDR;
    logic [2*DATA_WIDTH-1:0]      rv_ram [0:RV_DEPTH-1];
    logic [REVERB_ADDR-1:0]       rv_wr;
    logic [2*DATA_WIDTH-1:0]      rv_rd_q;
    localparam logic [REVERB_ADDR-1:0] RV_D = REVERB_DLY[REVERB_ADDR-1:0];
    wire  [REVERB_ADDR-1:0]       rv_rd_addr = rv_wr - RV_D;

    wire signed [DATA_WIDTH-1:0] rv_dly_l = rv_rd_q[2*DATA_WIDTH-1:DATA_WIDTH];
    wire signed [DATA_WIDTH-1:0] rv_dly_r = rv_rd_q[DATA_WIDTH-1:0];

    wire signed [DATA_WIDTH-1:0] rv_l =
        sat(((64'(sample_left_in)  <<< COEF_FRAC) + (RV_G * rv_dly_l)) >>> COEF_FRAC);
    wire signed [DATA_WIDTH-1:0] rv_r =
        sat(((64'(sample_right_in) <<< COEF_FRAC) + (RV_G * rv_dly_r)) >>> COEF_FRAC);

    // Continuous read (address only moves once per sample → settled long
    // before the next sample). Writes zeros when not in reverb so the tail
    // is flushed within one delay period — no big reset needed.
    always_ff @(posedge clk) begin
        rv_rd_q <= rv_ram[rv_rd_addr];
        if (sample_valid)
            rv_ram[rv_wr] <= (filter_mode == 2'b11 && mode_q == 2'b11)
                             ? {rv_l, rv_r} : '0;
    end
    always_ff @(posedge clk or negedge reset_reset_n)
        if (!reset_reset_n)    rv_wr <= '0;
        else if (sample_valid) rv_wr <= rv_wr + 1'b1;

    // ── Output / state update ────────────────────────────────────
    always_ff @(posedge clk or negedge reset_reset_n) begin
        if (!reset_reset_n) begin
            sample_valid_out <= 1'b0;
            sample_left_out  <= '0;  sample_right_out <= '0;
            x1l<='0; x2l<='0; y1l<='0; y2l<='0;
            x1r<='0; x2r<='0; y1r<='0; y2r<='0;
            mode_q <= 2'b00;
        end else begin
            sample_valid_out <= sample_valid;

            if (mode_q != filter_mode) begin
                // flush biquad state on mode switch; pass this sample raw
                x1l<='0; x2l<='0; y1l<='0; y2l<='0;
                x1r<='0; x2r<='0; y1r<='0; y2r<='0;
                mode_q <= filter_mode;
                if (sample_valid) begin
                    sample_left_out  <= sample_left_in;
                    sample_right_out <= sample_right_in;
                end
            end else if (sample_valid) begin
                unique case (filter_mode)
                    2'b00: begin
                        sample_left_out  <= sample_left_in;
                        sample_right_out <= sample_right_in;
                    end
                    2'b11: begin
                        sample_left_out  <= rv_l;
                        sample_right_out <= rv_r;
                    end
                    default: begin                  // 01 LP / 10 BP
                        sample_left_out  <= bq_l;
                        sample_right_out <= bq_r;
                        x2l<=x1l; x1l<=sample_left_in;  y2l<=y1l; y1l<=bq_l;
                        x2r<=x1r; x1r<=sample_right_in; y2r<=y1r; y1r<=bq_r;
                    end
                endcase
            end
        end
    end
endmodule