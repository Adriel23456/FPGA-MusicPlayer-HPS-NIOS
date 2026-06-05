module AudioBiquadFilter #(
    parameter int DATA_WIDTH = 16,
    parameter int COEF_WIDTH = 18,
    parameter int COEF_FRAC = 14
) (
    input  logic clk,
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
    localparam logic signed [COEF_WIDTH-1:0] LP_B0 = 18'sd1105;
    localparam logic signed [COEF_WIDTH-1:0] LP_B1 = 18'sd2210;
    localparam logic signed [COEF_WIDTH-1:0] LP_B2 = 18'sd1105;
    localparam logic signed [COEF_WIDTH-1:0] LP_A1 = -18'sd18726;
    localparam logic signed [COEF_WIDTH-1:0] LP_A2 = 18'sd6768;

    localparam logic signed [COEF_WIDTH-1:0] BP_B0 = 18'sd3385;
    localparam logic signed [COEF_WIDTH-1:0] BP_B1 = 18'sd0;
    localparam logic signed [COEF_WIDTH-1:0] BP_B2 = -18'sd3385;
    localparam logic signed [COEF_WIDTH-1:0] BP_A1 = -18'sd6058;
    localparam logic signed [COEF_WIDTH-1:0] BP_A2 = 18'sd9604;

    localparam logic signed [COEF_WIDTH-1:0] EQ_B0 = 18'sd17646;
    localparam logic signed [COEF_WIDTH-1:0] EQ_B1 = -18'sd25559;
    localparam logic signed [COEF_WIDTH-1:0] EQ_B2 = 18'sd10596;
    localparam logic signed [COEF_WIDTH-1:0] EQ_A1 = -18'sd25559;
    localparam logic signed [COEF_WIDTH-1:0] EQ_A2 = 18'sd15129;

    logic signed [DATA_WIDTH-1:0] x1_left;
    logic signed [DATA_WIDTH-1:0] x2_left;
    logic signed [DATA_WIDTH-1:0] y1_left;
    logic signed [DATA_WIDTH-1:0] y2_left;
    logic signed [DATA_WIDTH-1:0] x1_right;
    logic signed [DATA_WIDTH-1:0] x2_right;
    logic signed [DATA_WIDTH-1:0] y1_right;
    logic signed [DATA_WIDTH-1:0] y2_right;
    logic [1:0] mode_q;

    logic signed [COEF_WIDTH-1:0] b0;
    logic signed [COEF_WIDTH-1:0] b1;
    logic signed [COEF_WIDTH-1:0] b2;
    logic signed [COEF_WIDTH-1:0] a1;
    logic signed [COEF_WIDTH-1:0] a2;

    function automatic logic signed [DATA_WIDTH-1:0] saturate_sample(
        input logic signed [63:0] value
    );
        logic signed [63:0] max_pos;
        logic signed [63:0] min_neg;
        begin
            max_pos = (64'sd1 <<< (DATA_WIDTH - 1)) - 1;
            min_neg = - (64'sd1 <<< (DATA_WIDTH - 1));

            if (value > max_pos) begin
                saturate_sample = max_pos[DATA_WIDTH-1:0];
            end else if (value < min_neg) begin
                saturate_sample = min_neg[DATA_WIDTH-1:0];
            end else begin
                saturate_sample = value[DATA_WIDTH-1:0];
            end
        end
    endfunction

    always_comb begin
        unique case (filter_mode)
            2'b01: begin
                b0 = LP_B0; b1 = LP_B1; b2 = LP_B2; a1 = LP_A1; a2 = LP_A2;
            end
            2'b10: begin
                b0 = BP_B0; b1 = BP_B1; b2 = BP_B2; a1 = BP_A1; a2 = BP_A2;
            end
            2'b11: begin
                b0 = EQ_B0; b1 = EQ_B1; b2 = EQ_B2; a1 = EQ_A1; a2 = EQ_A2;
            end
            default: begin
                b0 = '0; b1 = '0; b2 = '0; a1 = '0; a2 = '0;
            end
        endcase
    end

    assign sample_ready = 1'b1;

    always_ff @(posedge clk or negedge reset_reset_n) begin
        logic signed [63:0] acc_left;
        logic signed [63:0] acc_right;

        if (!reset_reset_n) begin
            sample_valid_out <= 1'b0;
            sample_left_out  <= '0;
            sample_right_out <= '0;
            x1_left          <= '0;
            x2_left          <= '0;
            y1_left          <= '0;
            y2_left          <= '0;
            x1_right         <= '0;
            x2_right         <= '0;
            y1_right         <= '0;
            y2_right         <= '0;
            mode_q           <= 2'b00;
        end else begin
            if (mode_q != filter_mode) begin
                x1_left  <= '0;
                x2_left  <= '0;
                y1_left  <= '0;
                y2_left  <= '0;
                x1_right <= '0;
                x2_right <= '0;
                y1_right <= '0;
                y2_right <= '0;
                mode_q   <= filter_mode;
            end

            sample_valid_out <= sample_valid;

            if (sample_valid) begin
                if (filter_mode == 2'b00) begin
                    sample_left_out  <= sample_left_in;
                    sample_right_out <= sample_right_in;
                end else begin
                    acc_left = ($signed(b0) * $signed(sample_left_in))
                             + ($signed(b1) * $signed(x1_left))
                             + ($signed(b2) * $signed(x2_left))
                             - ($signed(a1) * $signed(y1_left))
                             - ($signed(a2) * $signed(y2_left));

                    acc_right = ($signed(b0) * $signed(sample_right_in))
                              + ($signed(b1) * $signed(x1_right))
                              + ($signed(b2) * $signed(x2_right))
                              - ($signed(a1) * $signed(y1_right))
                              - ($signed(a2) * $signed(y2_right));

                    sample_left_out  <= saturate_sample(acc_left >>> COEF_FRAC);
                    sample_right_out <= saturate_sample(acc_right >>> COEF_FRAC);

                    x2_left  <= x1_left;
                    x1_left  <= sample_left_in;
                    y2_left  <= y1_left;
                    y1_left  <= saturate_sample(acc_left >>> COEF_FRAC);

                    x2_right <= x1_right;
                    x1_right <= sample_right_in;
                    y2_right <= y1_right;
                    y1_right <= saturate_sample(acc_right >>> COEF_FRAC);
                end
            end
        end
    end
endmodule