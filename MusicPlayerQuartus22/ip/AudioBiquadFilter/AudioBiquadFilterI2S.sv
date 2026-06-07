// AudioBiquadFilterI2S.sv
// Hardware I2S interception with biquad filter.
// Protocol: Philips I2S, 64 BCLKs/frame (32 left + 32 right), 16-bit data.
// Latency:  1 audio frame (~20.8 µs @ 48 kHz) — inaudible.

module AudioBiquadFilterI2S #(
    parameter int DATA_WIDTH = 16,
    parameter int COEF_WIDTH = 18,
    parameter int COEF_FRAC  = 14
) (
    input  logic        reset_n,        // active-low reset
    input  logic        bclk,           // I2S bit clock from codec (3.072 MHz)
    input  logic        lrclk,          // I2S LR clock from codec (48 kHz)
    input  logic        dacdat_in,      // serial audio from Platform Designer
    input  logic [1:0]  filter_mode,    // 00=bypass 01=LP 10=BP 11=EQ (from filter_sw)
    output logic        dacdat_out      // filtered serial audio to WM8731
);

    // ── 1. LRCLK edge detection (posedge domain) ─────────────────
    // fall_lr / rise_lr are combinational, stable for a full BCLK period
    // → safe to use in the negedge serializer block at FPGA-typical speeds.
    logic lrclk_pos;
    always_ff @(posedge bclk or negedge reset_n) begin
        if (!reset_n) lrclk_pos <= 1'b0;
        else          lrclk_pos <= lrclk;
    end

    logic fall_lr, rise_lr;
    assign fall_lr =  lrclk_pos && !lrclk;   // → left channel starts
    assign rise_lr = !lrclk_pos &&  lrclk;   // → right channel starts

    // ── 2. Per-half-frame bit counter ────────────────────────────
    // Resets on both LRCLK edges.
    // bit_cnt = 0: edge detection cycle
    // bit_cnt = 1..DATA_WIDTH: data bits (MSB first, Philips I2S 1-BCLK delay)
    logic [4:0] bit_cnt;
    always_ff @(posedge bclk or negedge reset_n) begin
        if (!reset_n)              bit_cnt <= '0;
        else if (fall_lr || rise_lr) bit_cnt <= '0;
        else                        bit_cnt <= bit_cnt + 1;
    end

    // ── 3. Deserializer ──────────────────────────────────────────
    // des_left is stable long before sample_valid fires (settled 16+ BCLKs earlier).
    // des_right is written via NBA at the same posedge as sample_valid, so we
    // pipeline both through a registered buffer (filter_*) 1 BCLK later
    // to guarantee both are settled when filter_sample_valid fires.
    logic [DATA_WIDTH-1:0]        des_shift;
    logic signed [DATA_WIDTH-1:0] des_left, des_right;
    logic                         sample_valid;

    logic signed [DATA_WIDTH-1:0] filter_left_in, filter_right_in;
    logic                         filter_sample_valid;

    always_ff @(posedge bclk or negedge reset_n) begin
        if (!reset_n) begin
            des_shift           <= '0;
            des_left            <= '0;
            des_right           <= '0;
            sample_valid        <= 1'b0;
            filter_left_in      <= '0;
            filter_right_in     <= '0;
            filter_sample_valid <= 1'b0;
        end else begin
            sample_valid        <= 1'b0;

            // Delay valid by 1 BCLK so des_right NBA is settled
            filter_sample_valid <= sample_valid;
            if (sample_valid) begin
                filter_left_in  <= des_left;
                filter_right_in <= des_right;  // NBA complete from previous cycle ✓
            end

            // Shift in bits at bit_cnt 1..DATA_WIDTH-1 (MSB first)
            if (bit_cnt >= 1 && bit_cnt < DATA_WIDTH)
                des_shift <= {des_shift[DATA_WIDTH-2:0], dacdat_in};

            // Capture last bit and latch channel
            if (bit_cnt == DATA_WIDTH) begin
                if (!lrclk)
                    des_left <= {des_shift[DATA_WIDTH-2:0], dacdat_in};
                else begin
                    des_right    <= {des_shift[DATA_WIDTH-2:0], dacdat_in};
                    sample_valid <= 1'b1;   // both channels ready
                end
            end
        end
    end

    // ── 4. Biquad filter core (clocked by bclk) ──────────────────
    logic signed [DATA_WIDTH-1:0] filt_left_out, filt_right_out;
    logic                         filt_valid_out, filt_ready;

    AudioBiquadFilter #(
        .DATA_WIDTH(DATA_WIDTH),
        .COEF_WIDTH(COEF_WIDTH),
        .COEF_FRAC (COEF_FRAC)
    ) filter_core (
        .clk              (bclk),
        .reset_reset_n    (reset_n),
        .filter_mode      (filter_mode),
        .sample_valid     (filter_sample_valid),
        .sample_left_in   (filter_left_in),
        .sample_right_in  (filter_right_in),
        .sample_ready     (filt_ready),
        .sample_valid_out (filt_valid_out),
        .sample_left_out  (filt_left_out),
        .sample_right_out (filt_right_out)
    );

    // ── 5. Output buffer ─────────────────────────────────────────
    // Updated during padding BCLKs, well before the next LRCLK edge.
    logic signed [DATA_WIDTH-1:0] buf_left, buf_right;

    always_ff @(posedge bclk or negedge reset_n) begin
        if (!reset_n) begin
            buf_left  <= '0;
            buf_right <= '0;
        end else if (filt_valid_out) begin
            buf_left  <= filt_left_out;
            buf_right <= filt_right_out;
        end
    end

    // ── 6. Serializer (negedge domain) ───────────────────────────
    // Drives DACDAT on negedge BCLK → stable when WM8731 samples on posedge BCLK.
    // fall_lr/rise_lr are combinational and stable for the full BCLK period,
    // so reading them here is safe at 3.072 MHz FPGA speeds.
    logic [DATA_WIDTH-1:0] ser_shift;
    logic [4:0]            ser_cnt;

    always_ff @(negedge bclk or negedge reset_n) begin
        if (!reset_n) begin
            ser_shift  <= '0;
            ser_cnt    <= '0;
            dacdat_out <= 1'b0;
        end else if (fall_lr) begin
            // Left channel: output MSB immediately (Philips I2S 1-BCLK delay achieved)
            dacdat_out <= buf_left[DATA_WIDTH-1];
            ser_shift  <= {buf_left[DATA_WIDTH-2:0], 1'b0};
            ser_cnt    <= 5'd1;
        end else if (rise_lr) begin
            // Right channel: same
            dacdat_out <= buf_right[DATA_WIDTH-1];
            ser_shift  <= {buf_right[DATA_WIDTH-2:0], 1'b0};
            ser_cnt    <= 5'd1;
        end else if (ser_cnt > 0 && ser_cnt < DATA_WIDTH) begin
            // Remaining DATA_WIDTH-1 bits
            dacdat_out <= ser_shift[DATA_WIDTH-1];
            ser_shift  <= {ser_shift[DATA_WIDTH-2:0], 1'b0};
            ser_cnt    <= ser_cnt + 1;
        end else begin
            dacdat_out <= 1'b0;  // padding zeros (bits 17..32)
        end
    end

endmodule