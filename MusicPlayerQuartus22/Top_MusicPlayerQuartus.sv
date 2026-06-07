`timescale 1 ps / 1 ps
module Top_MusicPlayerQuartus #(
    parameter int unsigned CLK_FREQ = 50_000_000
) (
    input  logic        clk,
    input  logic        reset_reset_n,

    inout  wire         audio_config_export_SDAT,
    output logic        audio_config_export_SCLK,
    input  logic        audio_export_BCLK,
    output logic        audio_export_DACDAT,
    input  logic        audio_export_DACLRCK,
    output wire         audio_clk_export_clk,

    input  logic [3:0]  buttons_input_export,
    input  logic        switch_input_export,

    output logic        vga_outputs_CLK,
    output logic        vga_outputs_HS,
    output logic        vga_outputs_VS,
    output logic        vga_outputs_BLANK,
    output logic        vga_outputs_SYNC,
    output logic [7:0]  vga_outputs_R,
    output logic [7:0]  vga_outputs_G,
    output logic [7:0]  vga_outputs_B,

    output logic [6:0]  seg_min_tens,
    output logic [6:0]  seg_min_units,
    output logic [6:0]  seg_sec_tens,
    output logic [6:0]  seg_sec_units,

    input  logic [1:0]  filter_sw,
    output logic [6:0]  filter_seg_out,

    input  wire         hps_arm_h2f_mpu_events_eventi,
    output wire         hps_arm_h2f_mpu_events_evento,
    output wire [1:0]   hps_arm_h2f_mpu_events_standbywfe,
    output wire [1:0]   hps_arm_h2f_mpu_events_standbywfi,

    output wire [12:0]  memory_mem_a,
    output wire [2:0]   memory_mem_ba,
    output wire         memory_mem_ck,
    output wire         memory_mem_ck_n,
    output wire         memory_mem_cke,
    output wire         memory_mem_cs_n,
    output wire         memory_mem_ras_n,
    output wire         memory_mem_cas_n,
    output wire         memory_mem_we_n,
    output wire         memory_mem_reset_n,
    inout  wire [7:0]   memory_mem_dq,
    inout  wire         memory_mem_dqs,
    inout  wire         memory_mem_dqs_n,
    output wire         memory_mem_odt,
    output wire         memory_mem_dm,
    input  wire         memory_oct_rzqin,

    output wire         hps_io_hps_io_emac0_inst_TX_CLK,
    output wire         hps_io_hps_io_emac0_inst_TXD0,
    output wire         hps_io_hps_io_emac0_inst_TXD1,
    output wire         hps_io_hps_io_emac0_inst_TXD2,
    output wire         hps_io_hps_io_emac0_inst_TXD3,
    input  wire         hps_io_hps_io_emac0_inst_RXD0,
    inout  wire         hps_io_hps_io_emac0_inst_MDIO,
    output wire         hps_io_hps_io_emac0_inst_MDC,
    input  wire         hps_io_hps_io_emac0_inst_RX_CTL,
    output wire         hps_io_hps_io_emac0_inst_TX_CTL,
    input  wire         hps_io_hps_io_emac0_inst_RX_CLK,
    input  wire         hps_io_hps_io_emac0_inst_RXD1,
    input  wire         hps_io_hps_io_emac0_inst_RXD2,
    input  wire         hps_io_hps_io_emac0_inst_RXD3,

    inout  wire         hps_io_hps_io_sdio_inst_CMD,
    inout  wire         hps_io_hps_io_sdio_inst_D0,
    inout  wire         hps_io_hps_io_sdio_inst_D1,
    output wire         hps_io_hps_io_sdio_inst_CLK,
    inout  wire         hps_io_hps_io_sdio_inst_D2,
    inout  wire         hps_io_hps_io_sdio_inst_D3
);

    logic clk_25mhz = 1'b0;
    always_ff @(posedge clk) clk_25mhz <= ~clk_25mhz;

    logic [1:0] timer_ctrl_wire;
    logic [1:0] timer_status_wire;

    // ── Platform Designer (filter now lives inside) ───────────────
    MusicPlayerPlatformDesign platform (
        .clk_clk                                (clk),
        .vga_clk_clk                            (clk_25mhz),
        .reset_reset_n                          (reset_reset_n),

        // Audio — direct connections, no interception needed
        .audio_config_export_SDAT               (audio_config_export_SDAT),
        .audio_config_export_SCLK               (audio_config_export_SCLK),
        .audio_export_BCLK                      (audio_export_BCLK),
        .audio_export_DACDAT                    (audio_export_DACDAT),
        .audio_export_DACLRCK                   (audio_export_DACLRCK),
        .audio_clk_export_clk                   (audio_clk_export_clk),

        // Filter switch — drives AudioBiquadFilterConduit inside PD
        .filter_select_filter_sw                (filter_sw),

        .buttons_input_export                   (buttons_input_export),
        .switch_input_export                    (switch_input_export),

        .timer_ctrl_output_export               (timer_ctrl_wire),
        .timer_status_input_export              (timer_status_wire),

        .vga_outputs_CLK                        (vga_outputs_CLK),
        .vga_outputs_HS                         (vga_outputs_HS),
        .vga_outputs_VS                         (vga_outputs_VS),
        .vga_outputs_BLANK                      (vga_outputs_BLANK),
        .vga_outputs_SYNC                       (vga_outputs_SYNC),
        .vga_outputs_R                          (vga_outputs_R),
        .vga_outputs_G                          (vga_outputs_G),
        .vga_outputs_B                          (vga_outputs_B),

        .hps_arm_h2f_mpu_events_eventi          (hps_arm_h2f_mpu_events_eventi),
        .hps_arm_h2f_mpu_events_evento          (hps_arm_h2f_mpu_events_evento),
        .hps_arm_h2f_mpu_events_standbywfe      (hps_arm_h2f_mpu_events_standbywfe),
        .hps_arm_h2f_mpu_events_standbywfi      (hps_arm_h2f_mpu_events_standbywfi),

        .memory_mem_a                           (memory_mem_a),
        .memory_mem_ba                          (memory_mem_ba),
        .memory_mem_ck                          (memory_mem_ck),
        .memory_mem_ck_n                        (memory_mem_ck_n),
        .memory_mem_cke                         (memory_mem_cke),
        .memory_mem_cs_n                        (memory_mem_cs_n),
        .memory_mem_ras_n                       (memory_mem_ras_n),
        .memory_mem_cas_n                       (memory_mem_cas_n),
        .memory_mem_we_n                        (memory_mem_we_n),
        .memory_mem_reset_n                     (memory_mem_reset_n),
        .memory_mem_dq                          (memory_mem_dq),
        .memory_mem_dqs                         (memory_mem_dqs),
        .memory_mem_dqs_n                       (memory_mem_dqs_n),
        .memory_mem_odt                         (memory_mem_odt),
        .memory_mem_dm                          (memory_mem_dm),
        .memory_oct_rzqin                       (memory_oct_rzqin),

        .hps_io_hps_io_emac0_inst_TX_CLK        (hps_io_hps_io_emac0_inst_TX_CLK),
        .hps_io_hps_io_emac0_inst_TXD0          (hps_io_hps_io_emac0_inst_TXD0),
        .hps_io_hps_io_emac0_inst_TXD1          (hps_io_hps_io_emac0_inst_TXD1),
        .hps_io_hps_io_emac0_inst_TXD2          (hps_io_hps_io_emac0_inst_TXD2),
        .hps_io_hps_io_emac0_inst_TXD3          (hps_io_hps_io_emac0_inst_TXD3),
        .hps_io_hps_io_emac0_inst_RXD0          (hps_io_hps_io_emac0_inst_RXD0),
        .hps_io_hps_io_emac0_inst_MDIO          (hps_io_hps_io_emac0_inst_MDIO),
        .hps_io_hps_io_emac0_inst_MDC           (hps_io_hps_io_emac0_inst_MDC),
        .hps_io_hps_io_emac0_inst_RX_CTL        (hps_io_hps_io_emac0_inst_RX_CTL),
        .hps_io_hps_io_emac0_inst_TX_CTL        (hps_io_hps_io_emac0_inst_TX_CTL),
        .hps_io_hps_io_emac0_inst_RX_CLK        (hps_io_hps_io_emac0_inst_RX_CLK),
        .hps_io_hps_io_emac0_inst_RXD1          (hps_io_hps_io_emac0_inst_RXD1),
        .hps_io_hps_io_emac0_inst_RXD2          (hps_io_hps_io_emac0_inst_RXD2),
        .hps_io_hps_io_emac0_inst_RXD3          (hps_io_hps_io_emac0_inst_RXD3),

        .hps_io_hps_io_sdio_inst_CMD            (hps_io_hps_io_sdio_inst_CMD),
        .hps_io_hps_io_sdio_inst_D0             (hps_io_hps_io_sdio_inst_D0),
        .hps_io_hps_io_sdio_inst_D1             (hps_io_hps_io_sdio_inst_D1),
        .hps_io_hps_io_sdio_inst_CLK            (hps_io_hps_io_sdio_inst_CLK),
        .hps_io_hps_io_sdio_inst_D2             (hps_io_hps_io_sdio_inst_D2),
        .hps_io_hps_io_sdio_inst_D3             (hps_io_hps_io_sdio_inst_D3)
    );

    // ── MMSS Timer ────────────────────────────────────────────────
    MMSS_Timer #(.CLK_FREQ(CLK_FREQ)) timer_inst (
        .clk          (clk),
        .timer_ctrl   (timer_ctrl_wire),
        .timer_status (timer_status_wire),
        .seg_min_tens  (seg_min_tens),
        .seg_min_units (seg_min_units),
        .seg_sec_tens  (seg_sec_tens),
        .seg_sec_units (seg_sec_units)
    );

    // ── Filter 7-seg display (filter_sw shared with PD) ──────────
    Filter_Decoder filter_inst (
        .sw      (filter_sw),
        .seg_out (filter_seg_out)
    );

endmodule