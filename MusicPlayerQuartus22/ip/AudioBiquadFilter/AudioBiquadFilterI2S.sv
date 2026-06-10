// AudioBiquadFilterI2S.sv
// I2S/Left-Justified interception with DSP filtering.
// Wire format: Left-Justified (FMT_I2S=0), 16-bit, left channel while DACLRCK
// is HIGH — this is what altera_up_avalon_audio + AV-Config auto-init use.
// Codec is bus master (BCLK/DACLRCK are inputs). Latency: 1 audio frame.

module AudioBiquadFilterI2S #(
    parameter int DATA_WIDTH = 16,
    parameter int COEF_WIDTH = 18,
    parameter int COEF_FRAC  = 14,
    parameter bit FMT_I2S    = 1'b0   // 0 = Left-Justified (UP cores), 1 = Philips I2S
) (
    input  logic        reset_n,
    input  logic        bclk,
    input  logic        lrclk,
    input  logic        dacdat_in,    // serial data from AUDIO_OUT
    input  logic [1:0]  filter_mode,  // 00=bypass 01=LP 10=BP 11=reverb
    output logic        dacdat_out    // serial data to WM8731 pin
);
    localparam bit LEFT_WHEN_HIGH = !FMT_I2S;  // LJ: left=high, I2S: left=low

    // ── Reset synchronizer into BCLK domain ─────────────────────
    logic [1:0] rst_sync;
    always_ff @(posedge bclk or negedge reset_n)
        if (!reset_n) rst_sync <= 2'b00;
        else          rst_sync <= {rst_sync[0], 1'b1};
    wire rst_n = rst_sync[1];

    // ── filter_mode synchronizer (slide switches are async) ─────
    logic [1:0] mode_m, mode_s;
    always_ff @(posedge bclk or negedge rst_n)
        if (!rst_n) begin mode_m <= '0; mode_s <= '0; end
        else        begin mode_m <= filter_mode; mode_s <= mode_m; end

    // ── LRCLK edge detect — POSEDGE domain only ─────────────────
    // LRCLK changes 0..10 ns after a BCLK falling edge (codec tDL),
    // so sampling it on negedges is a race. Posedge sampling is safe.
    logic lrclk_pos, load_tgl, load_is_left;
    always_ff @(posedge bclk or negedge rst_n) begin
        if (!rst_n) begin
            lrclk_pos <= 1'b0; load_tgl <= 1'b0; load_is_left <= 1'b0;
        end else begin
            lrclk_pos <= lrclk;
            if (lrclk != lrclk_pos) begin
                load_tgl     <= ~load_tgl;                  // tell serializer
                load_is_left <= (lrclk == LEFT_WHEN_HIGH);
            end
        end
    end

    // ── Deserializer (posedge — same instant the codec would sample) ──
    // LJ: MSB is valid AT the edge-detect posedge → capture it there.
    // I2S: MSB arrives one posedge later.
    logic [5:0]                   rx_cnt;
    logic [DATA_WIDTH-1:0]        rx_shift;
    logic                         rx_is_left;
    logic signed [DATA_WIDTH-1:0] des_left, des_right;
    logic                         sample_valid;

    always_ff @(posedge bclk or negedge rst_n) begin
        if (!rst_n) begin
            rx_cnt <= 6'(DATA_WIDTH); rx_shift <= '0; rx_is_left <= 1'b0;
            des_left <= '0; des_right <= '0; sample_valid <= 1'b0;
        end else begin
            sample_valid <= 1'b0;
            if (lrclk != lrclk_pos) begin                   // new half-frame
                rx_is_left <= (lrclk == LEFT_WHEN_HIGH);
                if (FMT_I2S) begin
                    rx_cnt <= 6'd0;                          // MSB next posedge
                end else begin
                    rx_shift <= {{(DATA_WIDTH-1){1'b0}}, dacdat_in}; // MSB now
                    rx_cnt   <= 6'd1;
                end
            end else if (rx_cnt < 6'(DATA_WIDTH)) begin
                rx_shift <= {rx_shift[DATA_WIDTH-2:0], dacdat_in};
                rx_cnt   <= rx_cnt + 6'd1;
                if (rx_cnt == 6'(DATA_WIDTH-1)) begin        // last bit
                    if (rx_is_left)
                        des_left <= {rx_shift[DATA_WIDTH-2:0], dacdat_in};
                    else begin
                        des_right    <= {rx_shift[DATA_WIDTH-2:0], dacdat_in};
                        sample_valid <= 1'b1;                // L+R pair ready
                    end
                end
            end
        end
    end

    // ── Filter core (bclk domain) ────────────────────────────────
    logic signed [DATA_WIDTH-1:0] filt_l, filt_r;
    logic                         filt_v;

    AudioBiquadFilter #(
        .DATA_WIDTH(DATA_WIDTH), .COEF_WIDTH(COEF_WIDTH), .COEF_FRAC(COEF_FRAC)
    ) filter_core (
        .clk              (bclk),
        .reset_reset_n    (rst_n),
        .filter_mode      (mode_s),
        .sample_valid     (sample_valid),
        .sample_left_in   (des_left),
        .sample_right_in  (des_right),
        .sample_ready     (),
        .sample_valid_out (filt_v),
        .sample_left_out  (filt_l),
        .sample_right_out (filt_r)
    );

    logic signed [DATA_WIDTH-1:0] buf_left, buf_right;
    always_ff @(posedge bclk or negedge rst_n)
        if (!rst_n)      begin buf_left <= '0;     buf_right <= '0;     end
        else if (filt_v) begin buf_left <= filt_l; buf_right <= filt_r; end

    // ── Serializer (negedge shift, posedge-safe handshake) ───────
    // Load request crosses via the load_tgl toggle: the first negedge
    // after the edge-detect posedge performs the load — race-free.
    logic                  load_tgl_q;
    logic [DATA_WIDTH-1:0] tx_shift;
    logic [5:0]            tx_cnt;
    logic                  tx_bit;

    always_ff @(negedge bclk or negedge rst_n) begin
        if (!rst_n) begin
            load_tgl_q <= 1'b0; tx_shift <= '0;
            tx_cnt <= 6'(DATA_WIDTH); tx_bit <= 1'b0;
        end else if (load_tgl_q != load_tgl) begin
            logic [DATA_WIDTH-1:0] w;
            w = load_is_left ? buf_left : buf_right;
            load_tgl_q <= load_tgl;
            if (FMT_I2S) begin
                tx_bit   <= w[DATA_WIDTH-1];   // MSB on 2nd rising edge (I2S)
                tx_shift <= w << 1;
                tx_cnt   <= 6'd1;
            end else begin
                tx_bit   <= w[DATA_WIDTH-2];   // MSB already out (comb path)
                tx_shift <= w << 2;
                tx_cnt   <= 6'd2;
            end
        end else if (tx_cnt < 6'(DATA_WIDTH)) begin
            tx_bit   <= tx_shift[DATA_WIDTH-1];
            tx_shift <= tx_shift << 1;
            tx_cnt   <= tx_cnt + 6'd1;
        end else begin
            tx_bit <= 1'b0;                    // padding zeros
        end
    end

    // LJ only: the MSB must already be valid at the FIRST rising edge after
    // the LRCLK transition — before any negedge load can happen. Drive it
    // combinationally during that first bit cell (window: LRCLK change →
    // first negedge load). Codec samples on posedges, so the handoff
    // glitch mid-low-half is harmless.
    wire msb_cell = !FMT_I2S &&
                    ((lrclk != lrclk_pos) || (load_tgl != load_tgl_q));
    wire [DATA_WIDTH-1:0] first_word =
                    (lrclk == LEFT_WHEN_HIGH) ? buf_left : buf_right;
    wire tx_out = msb_cell ? first_word[DATA_WIDTH-1] : tx_bit;

    // ── Mode 00: hard bypass — paint input straight onto the pin ─
    assign dacdat_out = (mode_s == 2'b00) ? dacdat_in : tx_out;

endmodule