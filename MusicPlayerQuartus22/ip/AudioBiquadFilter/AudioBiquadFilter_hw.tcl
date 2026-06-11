# AudioBiquadFilter_hw.tcl
# Place this file alongside AudioBiquadFilter.sv, AudioBiquadFilterI2S.sv,
# and AudioBiquadFilterConduit.sv in the same ip/AudioBiquadFilter/ folder.

package require -exact qsys 12.0

# ── Component metadata ────────────────────────────────────────────────────────
set_module_property NAME         AudioBiquadFilter
set_module_property DISPLAY_NAME "Audio Biquad Filter"
set_module_property VERSION      1.0
set_module_property GROUP        "Audio"
set_module_property DESCRIPTION  "Biquad IIR filter with full I2S conduit interception"
set_module_property AUTHOR       ""
set_module_property EDITABLE     false

# ── HDL files ─────────────────────────────────────────────────────────────────
add_fileset QUARTUS_SYNTH QUARTUS_SYNTH "" ""
set_fileset_property QUARTUS_SYNTH TOP_LEVEL AudioBiquadFilterConduit
add_fileset_file AudioBiquadFilter.sv        SYSTEM_VERILOG PATH AudioBiquadFilter.sv
add_fileset_file AudioBiquadFilterI2S.sv     SYSTEM_VERILOG PATH AudioBiquadFilterI2S.sv
add_fileset_file AudioBiquadFilterConduit.sv SYSTEM_VERILOG PATH AudioBiquadFilterConduit.sv

add_fileset SIM_VERILOG SIM_VERILOG "" ""
set_fileset_property SIM_VERILOG TOP_LEVEL AudioBiquadFilterConduit
add_fileset_file AudioBiquadFilter.sv        SYSTEM_VERILOG PATH AudioBiquadFilter.sv
add_fileset_file AudioBiquadFilterI2S.sv     SYSTEM_VERILOG PATH AudioBiquadFilterI2S.sv
add_fileset_file AudioBiquadFilterConduit.sv SYSTEM_VERILOG PATH AudioBiquadFilterConduit.sv

# ── Parameters ────────────────────────────────────────────────────────────────
add_parameter DATA_WIDTH INTEGER 16 "Audio sample width"
set_parameter_property DATA_WIDTH HDL_PARAMETER true

add_parameter COEF_WIDTH INTEGER 18 "Coefficient width"
set_parameter_property COEF_WIDTH HDL_PARAMETER true

add_parameter COEF_FRAC  INTEGER 14 "Coefficient fractional bits"
set_parameter_property COEF_FRAC  HDL_PARAMETER true

# ── Interface 1: System clock ─────────────────────────────────────────────────
add_interface clk clock end
set_interface_property clk ENABLED true
add_interface_port clk clk clk input 1

# ── Interface 2: System reset ─────────────────────────────────────────────────
add_interface reset reset end
set_interface_property reset ENABLED          true
set_interface_property reset associatedClock  clk
set_interface_property reset synchronousEdges DEASSERT
add_interface_port reset reset_reset_n reset_n input 1

# ── Interface 3: Audio PLL clock sink (18.432 MHz) ────────────────────────────
# Connect to: altera_up_avalon_audio_pll → audio_clk (clock source)
add_interface audio_pll_clk clock end
set_interface_property audio_pll_clk ENABLED true
add_interface_port audio_pll_clk audio_pll_clk clk input 1

# ── Interface 4: Internal conduit to altera_up_avalon_audio ──────
add_interface audio_pd conduit end
set_interface_property audio_pd ENABLED true
add_interface_port audio_pd pd_audio_bclk    bclk    output 1
add_interface_port audio_pd pd_audio_daclrck daclrck output 1
add_interface_port audio_pd pd_audio_dacdat  dacdat  input  1

# ── Interface 5: Internal conduit to altera_up_avalon_audio_and_video_config ──
# IMPORTANT: audio_config_export_SDAT is the same physical HDL port as in
# Interface 7. Platform Designer wires both conduit connections to the same
# wire, so AUDIO_CONFIG drives/reads SDAT and the FPGA pin sees it directly.
add_interface audio_config_pd conduit end
set_interface_property audio_config_pd ENABLED true
add_interface_port audio_config_pd audio_config_export_SDAT export bidir 1
add_interface_port audio_config_pd pd_cfg_sclk              export input 1

# ── Interface 6: Export conduit — audio FPGA pins ─────────────────────────────
# Export as "audio_export" → generates: audio_export_BCLK,
#                                        audio_export_DACDAT, audio_export_DACLRCK
# These are the SAME port names the original design already had.
add_interface audio_export conduit start
set_interface_property audio_export ENABLED true
add_interface_port audio_export audio_export_BCLK    BCLK    input  1
add_interface_port audio_export audio_export_DACDAT  DACDAT  output 1
add_interface_port audio_export audio_export_DACLRCK DACLRCK input  1

# ── Interface 7: Export conduit — audio config FPGA pins ──────────────────────
# Export as "audio_config_export" → generates: audio_config_export_SDAT,
#                                               audio_config_export_SCLK
add_interface audio_config_export conduit start
set_interface_property audio_config_export ENABLED true
add_interface_port audio_config_export audio_config_export_SDAT SDAT bidir 1
add_interface_port audio_config_export audio_config_export_SCLK SCLK output 1

# ── Interface 8: Export conduit — MCLK FPGA pin ───────────────────────────────
# Export as "audio_clk_export" → generates: audio_clk_export_clk
add_interface audio_clk_export conduit start
set_interface_property audio_clk_export ENABLED true
add_interface_port audio_clk_export audio_clk_export_clk clk output 1

# ── Interface 9: Export conduit — filter switch ───────────────────────────────
# Export as "filter_select" → generates: filter_select_filter_sw
add_interface filter_select conduit end
set_interface_property filter_select ENABLED true
add_interface_port filter_select filter_sw filter_sw input 2