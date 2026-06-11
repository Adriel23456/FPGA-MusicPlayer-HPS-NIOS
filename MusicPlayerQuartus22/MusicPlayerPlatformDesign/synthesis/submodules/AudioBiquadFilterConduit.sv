// Platform Designer top-level module.
// Top-level of the AudioBiquadFilter Platform Designer component.
// Instantiates AudioBiquadFilterI2S which instantiates AudioBiquadFilter.
module AudioBiquadFilterConduit #(
    parameter int DATA_WIDTH = 16,
    parameter int COEF_WIDTH = 18,
    parameter int COEF_FRAC  = 14
) (
    // ── System (required for Platform Designer) ───────────────────
    input  logic        clk,
    input  logic        reset_reset_n,

    // ── PLL clock sink — connect to altera_up_avalon_audio_pll ────
    input  logic        audio_pll_clk,

    // ── Internal conduit → altera_up_avalon_audio ─────────────────
    // We PROVIDE bclk/daclrck back to AUDIO_OUT and RECEIVE its dacdat.
    output logic        pd_audio_bclk,
    output logic        pd_audio_daclrck,
    input  logic        pd_audio_dacdat,

    // ── Internal conduit → altera_up_avalon_audio_and_video_config ─
    // audio_config_export_SDAT: ONE physical port declared here,
    // listed in BOTH _hw.tcl conduit interfaces (audio_config_pd and
    // audio_config_export). Platform Designer therefore wires AUDIO_CONFIG's
    // I2C_SDAT and the exported top-level pin to the same net automatically.
    inout  wire         audio_config_export_SDAT,
    input  logic        pd_cfg_sclk,

    // ── Export conduit — audio FPGA pins ──────────────────────────
    // Exported as "audio_export" → same port names as original design.
    input  logic        audio_export_BCLK,
    output logic        audio_export_DACDAT,
    input  logic        audio_export_DACLRCK,

    // ── Export conduit — audio config FPGA pins ───────────────────
    // SDAT: shared port above. SCLK forwarded here.
    output logic        audio_config_export_SCLK,

    // ── Export conduit — MCLK FPGA pin ────────────────────────────
    // Exported as "audio_clk_export" → port name audio_clk_export_clk.
    output wire         audio_clk_export_clk,

    // ── Export conduit — filter switch ────────────────────────────
    // Exported as "filter_select" → port name filter_select_filter_sw.
    input  logic [1:0]  filter_sw
);

    // ── Passthroughs ──────────────────────────────────────────────
    assign pd_audio_bclk          = audio_export_BCLK;
    assign pd_audio_daclrck       = audio_export_DACLRCK;
    assign audio_config_export_SCLK = pd_cfg_sclk;
    assign audio_clk_export_clk   = audio_pll_clk;
    // audio_config_export_SDAT: no assign — single inout port shared
    // between both conduit interfaces in the _hw.tcl.

    // ── I2S biquad filter ─────────────────────────────────────────
    // Deserialize DACDAT from AUDIO_OUT → filter L/R → re-serialize to pin.
    AudioBiquadFilterI2S #(
        .DATA_WIDTH(DATA_WIDTH),
        .COEF_WIDTH(COEF_WIDTH),
        .COEF_FRAC (COEF_FRAC)
    ) filter_i2s (
        .reset_n     (reset_reset_n),
        .bclk        (audio_export_BCLK),
        .lrclk       (audio_export_DACLRCK),
        .dacdat_in   (pd_audio_dacdat),
        .filter_mode (filter_sw),
        .dacdat_out  (audio_export_DACDAT)
    );

endmodule