// Top_MusicPlayerQuartus.sv

`timescale 1 ps / 1 ps
module Top_MusicPlayerQuartus #(
    parameter int unsigned CLK_FREQ = 50_000_000
) (
    // ── Clocks & Reset ──────────────────────────────────────────
    input  logic        clk,
    input  logic        reset_reset_n,

    // ── Audio ────────────────────────────────────────────────────
    inout  wire         audio_config_export_SDAT,
    output logic        audio_config_export_SCLK,
    input  logic        audio_export_BCLK,
    output logic        audio_export_DACDAT,
    input  logic        audio_export_DACLRCK,

    // ── Buttons & Switches ───────────────────────────────────────
    input  logic [3:0]  buttons_input_export,
    input  logic        switch_input_export,

    // ── VGA ──────────────────────────────────────────────────────
    output logic        vga_outputs_CLK,
    output logic        vga_outputs_HS,
    output logic        vga_outputs_VS,
    output logic        vga_outputs_BLANK,
    output logic        vga_outputs_SYNC,
    output logic [7:0]  vga_outputs_R,
    output logic [7:0]  vga_outputs_G,
    output logic [7:0]  vga_outputs_B,

    // ── 7-Segment: MM:SS Timer ───────────────────────────────────
    output logic [6:0]  seg_min_tens,
    output logic [6:0]  seg_min_units,
    output logic [6:0]  seg_sec_tens,
    output logic [6:0]  seg_sec_units,

    // ── Filter_Decoder (standalone) ──────────────────────────────
    input  logic [1:0]  filter_sw,
    output logic [6:0]  filter_seg_out
);

    // ────────────────────────────────────────────────────────────
    // 25 MHz clock divider (50 MHz → 25 MHz toggle)
    // ────────────────────────────────────────────────────────────
    logic clk_25mhz = 1'b0;

    always_ff @(posedge clk)
        clk_25mhz <= ~clk_25mhz;

    // ────────────────────────────────────────────────────────────
    // Internal wires: Platform ↔ MMSS_Timer
    // ────────────────────────────────────────────────────────────
    logic [1:0] timer_ctrl_wire;
    logic [1:0] timer_status_wire;

    // ────────────────────────────────────────────────────────────
    // Platform Design (Nios II version)
    // ────────────────────────────────────────────────────────────
    MusicPlayerPlatformDesign platform (
        .clk_clk                     (clk),
        .vga_clk_clk                 (clk_25mhz),
        .reset_reset_n               (reset_reset_n),

        .audio_config_export_SDAT    (audio_config_export_SDAT),
        .audio_config_export_SCLK    (audio_config_export_SCLK),
        .audio_export_BCLK           (audio_export_BCLK),
        .audio_export_DACDAT         (audio_export_DACDAT),
        .audio_export_DACLRCK        (audio_export_DACLRCK),

        .buttons_input_export        (buttons_input_export),
        .switch_input_export         (switch_input_export),

        .timer_ctrl_output_export    (timer_ctrl_wire),
        .timer_status_input_export   (timer_status_wire),

        .vga_outputs_CLK             (vga_outputs_CLK),
        .vga_outputs_HS              (vga_outputs_HS),
        .vga_outputs_VS              (vga_outputs_VS),
        .vga_outputs_BLANK           (vga_outputs_BLANK),
        .vga_outputs_SYNC            (vga_outputs_SYNC),
        .vga_outputs_R               (vga_outputs_R),
        .vga_outputs_G               (vga_outputs_G),
        .vga_outputs_B               (vga_outputs_B)
    );

    // ────────────────────────────────────────────────────────────
    // MMSS_Timer
    // ────────────────────────────────────────────────────────────
    MMSS_Timer #(.CLK_FREQ(CLK_FREQ)) timer_inst (
        .clk          (clk),
        .timer_ctrl   (timer_ctrl_wire),
        .timer_status (timer_status_wire),
        .seg_min_tens  (seg_min_tens),
        .seg_min_units (seg_min_units),
        .seg_sec_tens  (seg_sec_tens),
        .seg_sec_units (seg_sec_units)
    );

    // ────────────────────────────────────────────────────────────
    // Filter_Decoder (standalone)
    // ────────────────────────────────────────────────────────────
    Filter_Decoder filter_inst (
        .sw      (filter_sw),
        .seg_out (filter_seg_out)
    );

endmodule