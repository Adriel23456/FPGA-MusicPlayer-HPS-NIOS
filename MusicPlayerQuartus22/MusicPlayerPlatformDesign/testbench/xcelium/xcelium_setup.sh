
# (C) 2001-2026 Altera Corporation. All rights reserved.
# Your use of Altera Corporation's design tools, logic functions and 
# other software and tools, and its AMPP partner logic functions, and 
# any output files any of the foregoing (including device programming 
# or simulation files), and any associated documentation or information 
# are expressly subject to the terms and conditions of the Altera 
# Program License Subscription Agreement, Altera MegaCore Function 
# License Agreement, or other applicable license agreement, including, 
# without limitation, that your use is for the sole purpose of 
# programming logic devices manufactured by Altera and sold by Altera 
# or its authorized distributors. Please refer to the applicable 
# agreement for further details.

# ACDS 22.1 922 linux 2026.05.29.11:25:37

# ----------------------------------------
# xcelium - auto-generated simulation script

# ----------------------------------------
# This script provides commands to simulate the following IP detected in
# your Quartus project:
#     MusicPlayerPlatformDesign_tb
# 
# Altera recommends that you source this Quartus-generated IP simulation
# script from your own customized top-level script, and avoid editing this
# generated script.
# 
# Xcelium Simulation Script.
# To write a top-level shell script that compiles Intel simulation libraries
# and the Quartus-generated IP in your project, along with your design and
# testbench files, copy the text from the TOP-LEVEL TEMPLATE section below
# into a new file, e.g. named "xcelium_sim.sh", and modify text as directed.
# 
# You can also modify the simulation flow to suit your needs. Set the
# following variables to 1 to disable their corresponding processes:
# - SKIP_FILE_COPY: skip copying ROM/RAM initialization files
# - SKIP_DEV_COM: skip compiling the Quartus EDA simulation library
# - SKIP_COM: skip compiling Quartus-generated IP simulation files
# - SKIP_ELAB and SKIP_SIM: skip elaboration and simulation
# 
# ----------------------------------------
# # TOP-LEVEL TEMPLATE - BEGIN
# #
# # QSYS_SIMDIR is used in the Quartus-generated IP simulation script to
# # construct paths to the files required to simulate the IP in your Quartus
# # project. By default, the IP script assumes that you are launching the
# # simulator from the IP script location. If launching from another
# # location, set QSYS_SIMDIR to the output directory you specified when you
# # generated the IP script, relative to the directory from which you launch
# # the simulator. In this case, you must also copy the generated files
# # "cds.lib" and "hdl.var" - plus the directory "cds_libs" if generated - 
# # into the location from which you launch the simulator, or incorporate
# # into any existing library setup.
# #
# # Run Quartus-generated IP simulation script once to compile Quartus EDA
# # simulation libraries and Quartus-generated IP simulation files, and copy
# # any ROM/RAM initialization files to the simulation directory.
# # - If necessary, specify any compilation options:
# #   USER_DEFINED_COMPILE_OPTIONS
# #   USER_DEFINED_VHDL_COMPILE_OPTIONS applied to vhdl compiler
# #   USER_DEFINED_VERILOG_COMPILE_OPTIONS applied to verilog compiler
# #
# source <script generation output directory>/xcelium/xcelium_setup.sh \
# SKIP_ELAB=1 \
# SKIP_SIM=1 \
# USER_DEFINED_COMPILE_OPTIONS=<compilation options for your design> \
# USER_DEFINED_VHDL_COMPILE_OPTIONS=<VHDL compilation options for your design> \
# USER_DEFINED_VERILOG_COMPILE_OPTIONS=<Verilog compilation options for your design> \
# QSYS_SIMDIR=<script generation output directory>
# #
# # Compile all design files and testbench files, including the top level.
# # (These are all the files required for simulation other than the files
# # compiled by the IP script)
# #
# xmvlog <compilation options> <design and testbench files>
# #
# # TOP_LEVEL_NAME is used in this script to set the top-level simulation or
# # testbench module/entity name.
# #
# # Run the IP script again to elaborate and simulate the top level:
# # - Specify TOP_LEVEL_NAME and USER_DEFINED_ELAB_OPTIONS.
# # - Override the default USER_DEFINED_SIM_OPTIONS. For example, to run
# #   until $finish(), set to an empty string: USER_DEFINED_SIM_OPTIONS="".
# #
# source <script generation output directory>/xcelium/xcelium_setup.sh \
# SKIP_FILE_COPY=1 \
# SKIP_DEV_COM=1 \
# SKIP_COM=1 \
# TOP_LEVEL_NAME=<simulation top> \
# USER_DEFINED_ELAB_OPTIONS=<elaboration options for your design> \
# USER_DEFINED_SIM_OPTIONS=<simulation options for your design>
# #
# # TOP-LEVEL TEMPLATE - END
# ----------------------------------------
# 
# IP SIMULATION SCRIPT
# ----------------------------------------
# If MusicPlayerPlatformDesign_tb is one of several IP cores in your
# Quartus project, you can generate a simulation script
# suitable for inclusion in your top-level simulation
# script by running the following command line:
# 
# ip-setup-simulation --quartus-project=<quartus project>
# 
# ip-setup-simulation will discover the Altera IP
# within the Quartus project, and generate a unified
# script which supports all the Altera IP within the design.
# ----------------------------------------
# ACDS 22.1 922 linux 2026.05.29.11:25:37
# ----------------------------------------
# initialize variables
TOP_LEVEL_NAME="MusicPlayerPlatformDesign_tb"
QSYS_SIMDIR="./../"
QUARTUS_INSTALL_DIR="/home/adriel/intelFPGA_lite/22.1std/quartus/"
SKIP_FILE_COPY=0
SKIP_DEV_COM=0
SKIP_COM=0
SKIP_ELAB=0
SKIP_SIM=0
USER_DEFINED_ELAB_OPTIONS=""
USER_DEFINED_SIM_OPTIONS="-input \"@run 100; exit\""

# ----------------------------------------
# overwrite variables - DO NOT MODIFY!
# This block evaluates each command line argument, typically used for 
# overwriting variables. An example usage:
#   sh <simulator>_setup.sh SKIP_SIM=1
for expression in "$@"; do
  eval $expression
  if [ $? -ne 0 ]; then
    echo "Error: This command line argument, \"$expression\", is/has an invalid expression." >&2
    exit $?
  fi
done

# ----------------------------------------
# initialize simulation properties - DO NOT MODIFY!
ELAB_OPTIONS=""
SIM_OPTIONS=""
if [[ `xmsim -version` != *"xmsim(64)"* ]]; then
  :
else
  :
fi

# ----------------------------------------
# create compilation libraries
mkdir -p ./libraries/work/
mkdir -p ./libraries/altera_common_sv_packages/
mkdir -p ./libraries/error_adapter_0/
mkdir -p ./libraries/avalon_st_adapter_002/
mkdir -p ./libraries/avalon_st_adapter/
mkdir -p ./libraries/crosser/
mkdir -p ./libraries/VGA_CHAR_BUFFER_avalon_char_buffer_slave_rsp_width_adapter/
mkdir -p ./libraries/rsp_mux_001/
mkdir -p ./libraries/rsp_mux/
mkdir -p ./libraries/rsp_demux_002/
mkdir -p ./libraries/rsp_demux/
mkdir -p ./libraries/cmd_mux_005/
mkdir -p ./libraries/cmd_mux/
mkdir -p ./libraries/cmd_demux_001/
mkdir -p ./libraries/cmd_demux/
mkdir -p ./libraries/VGA_CHAR_BUFFER_avalon_char_buffer_slave_burst_adapter/
mkdir -p ./libraries/router_007/
mkdir -p ./libraries/router_004/
mkdir -p ./libraries/router_002/
mkdir -p ./libraries/router_001/
mkdir -p ./libraries/router/
mkdir -p ./libraries/AUDIO_OUT_avalon_audio_slave_agent_rsp_fifo/
mkdir -p ./libraries/AUDIO_OUT_avalon_audio_slave_agent/
mkdir -p ./libraries/CPU_NIOS_II_data_master_agent/
mkdir -p ./libraries/AUDIO_OUT_avalon_audio_slave_translator/
mkdir -p ./libraries/CPU_NIOS_II_data_master_translator/
mkdir -p ./libraries/cpu/
mkdir -p ./libraries/rst_controller/
mkdir -p ./libraries/irq_mapper/
mkdir -p ./libraries/mm_interconnect_0/
mkdir -p ./libraries/VGA_CONTROLLER/
mkdir -p ./libraries/VGA_CHAR_BUFFER/
mkdir -p ./libraries/UART_NIOS_II/
mkdir -p ./libraries/TIMER_STATUS_INPUT/
mkdir -p ./libraries/TIMER_CTRL_OUTPUT/
mkdir -p ./libraries/REG_SW_INPUT/
mkdir -p ./libraries/REG_BTN_INPUT/
mkdir -p ./libraries/RAM_NIOS_II/
mkdir -p ./libraries/CPU_NIOS_II/
mkdir -p ./libraries/AUDIO_OUT/
mkdir -p ./libraries/AUDIO_CONFIG/
mkdir -p ./libraries/MusicPlayerPlatformDesign_inst_vga_outputs_bfm/
mkdir -p ./libraries/MusicPlayerPlatformDesign_inst_timer_status_input_bfm/
mkdir -p ./libraries/MusicPlayerPlatformDesign_inst_timer_ctrl_output_bfm/
mkdir -p ./libraries/MusicPlayerPlatformDesign_inst_switch_input_bfm/
mkdir -p ./libraries/MusicPlayerPlatformDesign_inst_reset_bfm/
mkdir -p ./libraries/MusicPlayerPlatformDesign_inst_clk_bfm/
mkdir -p ./libraries/MusicPlayerPlatformDesign_inst_buttons_input_bfm/
mkdir -p ./libraries/MusicPlayerPlatformDesign_inst_audio_export_bfm/
mkdir -p ./libraries/MusicPlayerPlatformDesign_inst_audio_config_export_bfm/
mkdir -p ./libraries/MusicPlayerPlatformDesign_inst/
mkdir -p ./libraries/altera_ver/
mkdir -p ./libraries/lpm_ver/
mkdir -p ./libraries/sgate_ver/
mkdir -p ./libraries/altera_mf_ver/
mkdir -p ./libraries/altera_lnsim_ver/
mkdir -p ./libraries/cyclonev_ver/
mkdir -p ./libraries/cyclonev_hssi_ver/
mkdir -p ./libraries/cyclonev_pcie_hip_ver/

# ----------------------------------------
# copy RAM/ROM files to simulation directory
if [ $SKIP_FILE_COPY -eq 0 ]; then
  cp -f $QSYS_SIMDIR/MusicPlayerPlatformDesign_tb/simulation/submodules/MusicPlayerPlatformDesign_CPU_NIOS_II_cpu_rf_ram_b.dat ./
  cp -f $QSYS_SIMDIR/MusicPlayerPlatformDesign_tb/simulation/submodules/MusicPlayerPlatformDesign_CPU_NIOS_II_cpu_rf_ram_b.hex ./
  cp -f $QSYS_SIMDIR/MusicPlayerPlatformDesign_tb/simulation/submodules/MusicPlayerPlatformDesign_CPU_NIOS_II_cpu_rf_ram_b.mif ./
  cp -f $QSYS_SIMDIR/MusicPlayerPlatformDesign_tb/simulation/submodules/MusicPlayerPlatformDesign_CPU_NIOS_II_cpu_rf_ram_a.mif ./
  cp -f $QSYS_SIMDIR/MusicPlayerPlatformDesign_tb/simulation/submodules/MusicPlayerPlatformDesign_CPU_NIOS_II_cpu_rf_ram_a.hex ./
  cp -f $QSYS_SIMDIR/MusicPlayerPlatformDesign_tb/simulation/submodules/MusicPlayerPlatformDesign_CPU_NIOS_II_cpu_rf_ram_a.dat ./
  cp -f $QSYS_SIMDIR/MusicPlayerPlatformDesign_tb/simulation/submodules/MusicPlayerPlatformDesign_CPU_NIOS_II_cpu_ociram_default_contents.hex ./
  cp -f $QSYS_SIMDIR/MusicPlayerPlatformDesign_tb/simulation/submodules/MusicPlayerPlatformDesign_CPU_NIOS_II_cpu_ociram_default_contents.dat ./
  cp -f $QSYS_SIMDIR/MusicPlayerPlatformDesign_tb/simulation/submodules/MusicPlayerPlatformDesign_CPU_NIOS_II_cpu_ociram_default_contents.mif ./
  cp -f $QSYS_SIMDIR/MusicPlayerPlatformDesign_tb/simulation/submodules/altera_up_video_char_mode_rom_128.mif ./
  cp -f $QSYS_SIMDIR/MusicPlayerPlatformDesign_tb/simulation/submodules/altera_up_video_fb_color_rom.mif ./
  cp -f $QSYS_SIMDIR/MusicPlayerPlatformDesign_tb/simulation/submodules/MusicPlayerPlatformDesign_RAM_NIOS_II.hex ./
fi

# ----------------------------------------
# compile device library files
if [ $SKIP_DEV_COM -eq 0 ]; then
  xmvlog $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS     "$QUARTUS_INSTALL_DIR/eda/sim_lib/altera_primitives.v"                      -work altera_ver           
  xmvlog $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS     "$QUARTUS_INSTALL_DIR/eda/sim_lib/220model.v"                               -work lpm_ver              
  xmvlog $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS     "$QUARTUS_INSTALL_DIR/eda/sim_lib/sgate.v"                                  -work sgate_ver            
  xmvlog $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS     "$QUARTUS_INSTALL_DIR/eda/sim_lib/altera_mf.v"                              -work altera_mf_ver        
  xmvlog -sv $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS "$QUARTUS_INSTALL_DIR/eda/sim_lib/altera_lnsim.sv"                          -work altera_lnsim_ver     
  xmvlog $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS     "$QUARTUS_INSTALL_DIR/eda/sim_lib/cadence/cyclonev_atoms_ncrypt.v"          -work cyclonev_ver         
  xmvlog $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS     "$QUARTUS_INSTALL_DIR/eda/sim_lib/cadence/cyclonev_hmi_atoms_ncrypt.v"      -work cyclonev_ver         
  xmvlog $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS     "$QUARTUS_INSTALL_DIR/eda/sim_lib/cyclonev_atoms.v"                         -work cyclonev_ver         
  xmvlog $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS     "$QUARTUS_INSTALL_DIR/eda/sim_lib/cadence/cyclonev_hssi_atoms_ncrypt.v"     -work cyclonev_hssi_ver    
  xmvlog $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS     "$QUARTUS_INSTALL_DIR/eda/sim_lib/cyclonev_hssi_atoms.v"                    -work cyclonev_hssi_ver    
  xmvlog $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS     "$QUARTUS_INSTALL_DIR/eda/sim_lib/cadence/cyclonev_pcie_hip_atoms_ncrypt.v" -work cyclonev_pcie_hip_ver
  xmvlog $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS     "$QUARTUS_INSTALL_DIR/eda/sim_lib/cyclonev_pcie_hip_atoms.v"                -work cyclonev_pcie_hip_ver
fi

# ----------------------------------------
# compile design files in correct order
if [ $SKIP_COM -eq 0 ]; then
  xmvlog -sv $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/MusicPlayerPlatformDesign_tb/simulation/submodules/verbosity_pkg.sv"                                                                     -work altera_common_sv_packages                                  -cdslib ./cds_libs/altera_common_sv_packages.cds.lib                                 
  xmvlog -sv $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/MusicPlayerPlatformDesign_tb/simulation/submodules/MusicPlayerPlatformDesign_mm_interconnect_0_avalon_st_adapter_002_error_adapter_0.sv" -work error_adapter_0                                            -cdslib ./cds_libs/error_adapter_0.cds.lib                                           
  xmvlog -sv $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/MusicPlayerPlatformDesign_tb/simulation/submodules/MusicPlayerPlatformDesign_mm_interconnect_0_avalon_st_adapter_error_adapter_0.sv"     -work error_adapter_0                                            -cdslib ./cds_libs/error_adapter_0.cds.lib                                           
  xmvlog $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS     "$QSYS_SIMDIR/MusicPlayerPlatformDesign_tb/simulation/submodules/MusicPlayerPlatformDesign_mm_interconnect_0_avalon_st_adapter_002.v"                  -work avalon_st_adapter_002                                      -cdslib ./cds_libs/avalon_st_adapter_002.cds.lib                                     
  xmvlog $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS     "$QSYS_SIMDIR/MusicPlayerPlatformDesign_tb/simulation/submodules/MusicPlayerPlatformDesign_mm_interconnect_0_avalon_st_adapter.v"                      -work avalon_st_adapter                                          -cdslib ./cds_libs/avalon_st_adapter.cds.lib                                         
  xmvlog -sv $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/MusicPlayerPlatformDesign_tb/simulation/submodules/altera_avalon_st_handshake_clock_crosser.v"                                           -work crosser                                                    -cdslib ./cds_libs/crosser.cds.lib                                                   
  xmvlog -sv $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/MusicPlayerPlatformDesign_tb/simulation/submodules/altera_avalon_st_clock_crosser.v"                                                     -work crosser                                                    -cdslib ./cds_libs/crosser.cds.lib                                                   
  xmvlog -sv $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/MusicPlayerPlatformDesign_tb/simulation/submodules/altera_avalon_st_pipeline_base.v"                                                     -work crosser                                                    -cdslib ./cds_libs/crosser.cds.lib                                                   
  xmvlog -sv $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/MusicPlayerPlatformDesign_tb/simulation/submodules/altera_std_synchronizer_nocut.v"                                                      -work crosser                                                    -cdslib ./cds_libs/crosser.cds.lib                                                   
  xmvlog -sv $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/MusicPlayerPlatformDesign_tb/simulation/submodules/altera_merlin_width_adapter.sv"                                                       -work VGA_CHAR_BUFFER_avalon_char_buffer_slave_rsp_width_adapter -cdslib ./cds_libs/VGA_CHAR_BUFFER_avalon_char_buffer_slave_rsp_width_adapter.cds.lib
  xmvlog -sv $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/MusicPlayerPlatformDesign_tb/simulation/submodules/altera_merlin_address_alignment.sv"                                                   -work VGA_CHAR_BUFFER_avalon_char_buffer_slave_rsp_width_adapter -cdslib ./cds_libs/VGA_CHAR_BUFFER_avalon_char_buffer_slave_rsp_width_adapter.cds.lib
  xmvlog -sv $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/MusicPlayerPlatformDesign_tb/simulation/submodules/altera_merlin_burst_uncompressor.sv"                                                  -work VGA_CHAR_BUFFER_avalon_char_buffer_slave_rsp_width_adapter -cdslib ./cds_libs/VGA_CHAR_BUFFER_avalon_char_buffer_slave_rsp_width_adapter.cds.lib
  xmvlog -sv $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/MusicPlayerPlatformDesign_tb/simulation/submodules/MusicPlayerPlatformDesign_mm_interconnect_0_rsp_mux_001.sv"                           -work rsp_mux_001                                                -cdslib ./cds_libs/rsp_mux_001.cds.lib                                               
  xmvlog -sv $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/MusicPlayerPlatformDesign_tb/simulation/submodules/altera_merlin_arbitrator.sv"                                                          -work rsp_mux_001                                                -cdslib ./cds_libs/rsp_mux_001.cds.lib                                               
  xmvlog -sv $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/MusicPlayerPlatformDesign_tb/simulation/submodules/MusicPlayerPlatformDesign_mm_interconnect_0_rsp_mux.sv"                               -work rsp_mux                                                    -cdslib ./cds_libs/rsp_mux.cds.lib                                                   
  xmvlog -sv $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/MusicPlayerPlatformDesign_tb/simulation/submodules/altera_merlin_arbitrator.sv"                                                          -work rsp_mux                                                    -cdslib ./cds_libs/rsp_mux.cds.lib                                                   
  xmvlog -sv $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/MusicPlayerPlatformDesign_tb/simulation/submodules/MusicPlayerPlatformDesign_mm_interconnect_0_rsp_demux_002.sv"                         -work rsp_demux_002                                              -cdslib ./cds_libs/rsp_demux_002.cds.lib                                             
  xmvlog -sv $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/MusicPlayerPlatformDesign_tb/simulation/submodules/MusicPlayerPlatformDesign_mm_interconnect_0_rsp_demux.sv"                             -work rsp_demux                                                  -cdslib ./cds_libs/rsp_demux.cds.lib                                                 
  xmvlog -sv $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/MusicPlayerPlatformDesign_tb/simulation/submodules/MusicPlayerPlatformDesign_mm_interconnect_0_cmd_mux_005.sv"                           -work cmd_mux_005                                                -cdslib ./cds_libs/cmd_mux_005.cds.lib                                               
  xmvlog -sv $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/MusicPlayerPlatformDesign_tb/simulation/submodules/altera_merlin_arbitrator.sv"                                                          -work cmd_mux_005                                                -cdslib ./cds_libs/cmd_mux_005.cds.lib                                               
  xmvlog -sv $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/MusicPlayerPlatformDesign_tb/simulation/submodules/MusicPlayerPlatformDesign_mm_interconnect_0_cmd_mux.sv"                               -work cmd_mux                                                    -cdslib ./cds_libs/cmd_mux.cds.lib                                                   
  xmvlog -sv $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/MusicPlayerPlatformDesign_tb/simulation/submodules/altera_merlin_arbitrator.sv"                                                          -work cmd_mux                                                    -cdslib ./cds_libs/cmd_mux.cds.lib                                                   
  xmvlog -sv $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/MusicPlayerPlatformDesign_tb/simulation/submodules/MusicPlayerPlatformDesign_mm_interconnect_0_cmd_demux_001.sv"                         -work cmd_demux_001                                              -cdslib ./cds_libs/cmd_demux_001.cds.lib                                             
  xmvlog -sv $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/MusicPlayerPlatformDesign_tb/simulation/submodules/MusicPlayerPlatformDesign_mm_interconnect_0_cmd_demux.sv"                             -work cmd_demux                                                  -cdslib ./cds_libs/cmd_demux.cds.lib                                                 
  xmvlog -sv $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/MusicPlayerPlatformDesign_tb/simulation/submodules/altera_merlin_burst_adapter.sv"                                                       -work VGA_CHAR_BUFFER_avalon_char_buffer_slave_burst_adapter     -cdslib ./cds_libs/VGA_CHAR_BUFFER_avalon_char_buffer_slave_burst_adapter.cds.lib    
  xmvlog -sv $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/MusicPlayerPlatformDesign_tb/simulation/submodules/altera_merlin_burst_adapter_uncmpr.sv"                                                -work VGA_CHAR_BUFFER_avalon_char_buffer_slave_burst_adapter     -cdslib ./cds_libs/VGA_CHAR_BUFFER_avalon_char_buffer_slave_burst_adapter.cds.lib    
  xmvlog -sv $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/MusicPlayerPlatformDesign_tb/simulation/submodules/altera_merlin_burst_adapter_13_1.sv"                                                  -work VGA_CHAR_BUFFER_avalon_char_buffer_slave_burst_adapter     -cdslib ./cds_libs/VGA_CHAR_BUFFER_avalon_char_buffer_slave_burst_adapter.cds.lib    
  xmvlog -sv $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/MusicPlayerPlatformDesign_tb/simulation/submodules/altera_merlin_burst_adapter_new.sv"                                                   -work VGA_CHAR_BUFFER_avalon_char_buffer_slave_burst_adapter     -cdslib ./cds_libs/VGA_CHAR_BUFFER_avalon_char_buffer_slave_burst_adapter.cds.lib    
  xmvlog -sv $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/MusicPlayerPlatformDesign_tb/simulation/submodules/altera_incr_burst_converter.sv"                                                       -work VGA_CHAR_BUFFER_avalon_char_buffer_slave_burst_adapter     -cdslib ./cds_libs/VGA_CHAR_BUFFER_avalon_char_buffer_slave_burst_adapter.cds.lib    
  xmvlog -sv $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/MusicPlayerPlatformDesign_tb/simulation/submodules/altera_wrap_burst_converter.sv"                                                       -work VGA_CHAR_BUFFER_avalon_char_buffer_slave_burst_adapter     -cdslib ./cds_libs/VGA_CHAR_BUFFER_avalon_char_buffer_slave_burst_adapter.cds.lib    
  xmvlog -sv $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/MusicPlayerPlatformDesign_tb/simulation/submodules/altera_default_burst_converter.sv"                                                    -work VGA_CHAR_BUFFER_avalon_char_buffer_slave_burst_adapter     -cdslib ./cds_libs/VGA_CHAR_BUFFER_avalon_char_buffer_slave_burst_adapter.cds.lib    
  xmvlog -sv $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/MusicPlayerPlatformDesign_tb/simulation/submodules/altera_merlin_address_alignment.sv"                                                   -work VGA_CHAR_BUFFER_avalon_char_buffer_slave_burst_adapter     -cdslib ./cds_libs/VGA_CHAR_BUFFER_avalon_char_buffer_slave_burst_adapter.cds.lib    
  xmvlog -sv $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/MusicPlayerPlatformDesign_tb/simulation/submodules/altera_avalon_st_pipeline_stage.sv"                                                   -work VGA_CHAR_BUFFER_avalon_char_buffer_slave_burst_adapter     -cdslib ./cds_libs/VGA_CHAR_BUFFER_avalon_char_buffer_slave_burst_adapter.cds.lib    
  xmvlog -sv $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/MusicPlayerPlatformDesign_tb/simulation/submodules/altera_avalon_st_pipeline_base.v"                                                     -work VGA_CHAR_BUFFER_avalon_char_buffer_slave_burst_adapter     -cdslib ./cds_libs/VGA_CHAR_BUFFER_avalon_char_buffer_slave_burst_adapter.cds.lib    
  xmvlog -sv $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/MusicPlayerPlatformDesign_tb/simulation/submodules/MusicPlayerPlatformDesign_mm_interconnect_0_router_007.sv"                            -work router_007                                                 -cdslib ./cds_libs/router_007.cds.lib                                                
  xmvlog -sv $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/MusicPlayerPlatformDesign_tb/simulation/submodules/MusicPlayerPlatformDesign_mm_interconnect_0_router_004.sv"                            -work router_004                                                 -cdslib ./cds_libs/router_004.cds.lib                                                
  xmvlog -sv $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/MusicPlayerPlatformDesign_tb/simulation/submodules/MusicPlayerPlatformDesign_mm_interconnect_0_router_002.sv"                            -work router_002                                                 -cdslib ./cds_libs/router_002.cds.lib                                                
  xmvlog -sv $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/MusicPlayerPlatformDesign_tb/simulation/submodules/MusicPlayerPlatformDesign_mm_interconnect_0_router_001.sv"                            -work router_001                                                 -cdslib ./cds_libs/router_001.cds.lib                                                
  xmvlog -sv $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/MusicPlayerPlatformDesign_tb/simulation/submodules/MusicPlayerPlatformDesign_mm_interconnect_0_router.sv"                                -work router                                                     -cdslib ./cds_libs/router.cds.lib                                                    
  xmvlog $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS     "$QSYS_SIMDIR/MusicPlayerPlatformDesign_tb/simulation/submodules/altera_avalon_sc_fifo.v"                                                              -work AUDIO_OUT_avalon_audio_slave_agent_rsp_fifo                -cdslib ./cds_libs/AUDIO_OUT_avalon_audio_slave_agent_rsp_fifo.cds.lib               
  xmvlog -sv $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/MusicPlayerPlatformDesign_tb/simulation/submodules/altera_merlin_slave_agent.sv"                                                         -work AUDIO_OUT_avalon_audio_slave_agent                         -cdslib ./cds_libs/AUDIO_OUT_avalon_audio_slave_agent.cds.lib                        
  xmvlog -sv $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/MusicPlayerPlatformDesign_tb/simulation/submodules/altera_merlin_burst_uncompressor.sv"                                                  -work AUDIO_OUT_avalon_audio_slave_agent                         -cdslib ./cds_libs/AUDIO_OUT_avalon_audio_slave_agent.cds.lib                        
  xmvlog -sv $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/MusicPlayerPlatformDesign_tb/simulation/submodules/altera_merlin_master_agent.sv"                                                        -work CPU_NIOS_II_data_master_agent                              -cdslib ./cds_libs/CPU_NIOS_II_data_master_agent.cds.lib                             
  xmvlog -sv $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/MusicPlayerPlatformDesign_tb/simulation/submodules/altera_merlin_slave_translator.sv"                                                    -work AUDIO_OUT_avalon_audio_slave_translator                    -cdslib ./cds_libs/AUDIO_OUT_avalon_audio_slave_translator.cds.lib                   
  xmvlog -sv $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/MusicPlayerPlatformDesign_tb/simulation/submodules/altera_merlin_master_translator.sv"                                                   -work CPU_NIOS_II_data_master_translator                         -cdslib ./cds_libs/CPU_NIOS_II_data_master_translator.cds.lib                        
  xmvlog $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS     "$QSYS_SIMDIR/MusicPlayerPlatformDesign_tb/simulation/submodules/MusicPlayerPlatformDesign_CPU_NIOS_II_cpu_debug_slave_sysclk.v"                       -work cpu                                                        -cdslib ./cds_libs/cpu.cds.lib                                                       
  xmvlog $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS     "$QSYS_SIMDIR/MusicPlayerPlatformDesign_tb/simulation/submodules/MusicPlayerPlatformDesign_CPU_NIOS_II_cpu_test_bench.v"                               -work cpu                                                        -cdslib ./cds_libs/cpu.cds.lib                                                       
  xmvlog $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS     "$QSYS_SIMDIR/MusicPlayerPlatformDesign_tb/simulation/submodules/MusicPlayerPlatformDesign_CPU_NIOS_II_cpu.v"                                          -work cpu                                                        -cdslib ./cds_libs/cpu.cds.lib                                                       
  xmvlog $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS     "$QSYS_SIMDIR/MusicPlayerPlatformDesign_tb/simulation/submodules/MusicPlayerPlatformDesign_CPU_NIOS_II_cpu_debug_slave_tck.v"                          -work cpu                                                        -cdslib ./cds_libs/cpu.cds.lib                                                       
  xmvlog $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS     "$QSYS_SIMDIR/MusicPlayerPlatformDesign_tb/simulation/submodules/MusicPlayerPlatformDesign_CPU_NIOS_II_cpu_debug_slave_wrapper.v"                      -work cpu                                                        -cdslib ./cds_libs/cpu.cds.lib                                                       
  xmvlog $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS     "$QSYS_SIMDIR/MusicPlayerPlatformDesign_tb/simulation/submodules/altera_reset_controller.v"                                                            -work rst_controller                                             -cdslib ./cds_libs/rst_controller.cds.lib                                            
  xmvlog $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS     "$QSYS_SIMDIR/MusicPlayerPlatformDesign_tb/simulation/submodules/altera_reset_synchronizer.v"                                                          -work rst_controller                                             -cdslib ./cds_libs/rst_controller.cds.lib                                            
  xmvlog -sv $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/MusicPlayerPlatformDesign_tb/simulation/submodules/MusicPlayerPlatformDesign_irq_mapper.sv"                                              -work irq_mapper                                                 -cdslib ./cds_libs/irq_mapper.cds.lib                                                
  xmvlog $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS     "$QSYS_SIMDIR/MusicPlayerPlatformDesign_tb/simulation/submodules/MusicPlayerPlatformDesign_mm_interconnect_0.v"                                        -work mm_interconnect_0                                          -cdslib ./cds_libs/mm_interconnect_0.cds.lib                                         
  xmvlog $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS     "$QSYS_SIMDIR/MusicPlayerPlatformDesign_tb/simulation/submodules/altera_up_avalon_video_vga_timing.v"                                                  -work VGA_CONTROLLER                                             -cdslib ./cds_libs/VGA_CONTROLLER.cds.lib                                            
  xmvlog $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS     "$QSYS_SIMDIR/MusicPlayerPlatformDesign_tb/simulation/submodules/MusicPlayerPlatformDesign_VGA_CONTROLLER.v"                                           -work VGA_CONTROLLER                                             -cdslib ./cds_libs/VGA_CONTROLLER.cds.lib                                            
  xmvlog $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS     "$QSYS_SIMDIR/MusicPlayerPlatformDesign_tb/simulation/submodules/altera_up_video_128_character_rom.v"                                                  -work VGA_CHAR_BUFFER                                            -cdslib ./cds_libs/VGA_CHAR_BUFFER.cds.lib                                           
  xmvlog $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS     "$QSYS_SIMDIR/MusicPlayerPlatformDesign_tb/simulation/submodules/altera_up_video_fb_color_rom.v"                                                       -work VGA_CHAR_BUFFER                                            -cdslib ./cds_libs/VGA_CHAR_BUFFER.cds.lib                                           
  xmvlog $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS     "$QSYS_SIMDIR/MusicPlayerPlatformDesign_tb/simulation/submodules/MusicPlayerPlatformDesign_VGA_CHAR_BUFFER.v"                                          -work VGA_CHAR_BUFFER                                            -cdslib ./cds_libs/VGA_CHAR_BUFFER.cds.lib                                           
  xmvlog $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS     "$QSYS_SIMDIR/MusicPlayerPlatformDesign_tb/simulation/submodules/MusicPlayerPlatformDesign_UART_NIOS_II.v"                                             -work UART_NIOS_II                                               -cdslib ./cds_libs/UART_NIOS_II.cds.lib                                              
  xmvlog $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS     "$QSYS_SIMDIR/MusicPlayerPlatformDesign_tb/simulation/submodules/MusicPlayerPlatformDesign_TIMER_STATUS_INPUT.v"                                       -work TIMER_STATUS_INPUT                                         -cdslib ./cds_libs/TIMER_STATUS_INPUT.cds.lib                                        
  xmvlog $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS     "$QSYS_SIMDIR/MusicPlayerPlatformDesign_tb/simulation/submodules/MusicPlayerPlatformDesign_TIMER_CTRL_OUTPUT.v"                                        -work TIMER_CTRL_OUTPUT                                          -cdslib ./cds_libs/TIMER_CTRL_OUTPUT.cds.lib                                         
  xmvlog $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS     "$QSYS_SIMDIR/MusicPlayerPlatformDesign_tb/simulation/submodules/MusicPlayerPlatformDesign_REG_SW_INPUT.v"                                             -work REG_SW_INPUT                                               -cdslib ./cds_libs/REG_SW_INPUT.cds.lib                                              
  xmvlog $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS     "$QSYS_SIMDIR/MusicPlayerPlatformDesign_tb/simulation/submodules/MusicPlayerPlatformDesign_REG_BTN_INPUT.v"                                            -work REG_BTN_INPUT                                              -cdslib ./cds_libs/REG_BTN_INPUT.cds.lib                                             
  xmvlog $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS     "$QSYS_SIMDIR/MusicPlayerPlatformDesign_tb/simulation/submodules/MusicPlayerPlatformDesign_RAM_NIOS_II.v"                                              -work RAM_NIOS_II                                                -cdslib ./cds_libs/RAM_NIOS_II.cds.lib                                               
  xmvlog $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS     "$QSYS_SIMDIR/MusicPlayerPlatformDesign_tb/simulation/submodules/MusicPlayerPlatformDesign_CPU_NIOS_II.v"                                              -work CPU_NIOS_II                                                -cdslib ./cds_libs/CPU_NIOS_II.cds.lib                                               
  xmvlog $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS     "$QSYS_SIMDIR/MusicPlayerPlatformDesign_tb/simulation/submodules/altera_up_audio_bit_counter.v"                                                        -work AUDIO_OUT                                                  -cdslib ./cds_libs/AUDIO_OUT.cds.lib                                                 
  xmvlog $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS     "$QSYS_SIMDIR/MusicPlayerPlatformDesign_tb/simulation/submodules/altera_up_audio_in_deserializer.v"                                                    -work AUDIO_OUT                                                  -cdslib ./cds_libs/AUDIO_OUT.cds.lib                                                 
  xmvlog $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS     "$QSYS_SIMDIR/MusicPlayerPlatformDesign_tb/simulation/submodules/altera_up_audio_out_serializer.v"                                                     -work AUDIO_OUT                                                  -cdslib ./cds_libs/AUDIO_OUT.cds.lib                                                 
  xmvlog $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS     "$QSYS_SIMDIR/MusicPlayerPlatformDesign_tb/simulation/submodules/altera_up_clock_edge.v"                                                               -work AUDIO_OUT                                                  -cdslib ./cds_libs/AUDIO_OUT.cds.lib                                                 
  xmvlog $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS     "$QSYS_SIMDIR/MusicPlayerPlatformDesign_tb/simulation/submodules/altera_up_sync_fifo.v"                                                                -work AUDIO_OUT                                                  -cdslib ./cds_libs/AUDIO_OUT.cds.lib                                                 
  xmvlog $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS     "$QSYS_SIMDIR/MusicPlayerPlatformDesign_tb/simulation/submodules/MusicPlayerPlatformDesign_AUDIO_OUT.v"                                                -work AUDIO_OUT                                                  -cdslib ./cds_libs/AUDIO_OUT.cds.lib                                                 
  xmvlog $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS     "$QSYS_SIMDIR/MusicPlayerPlatformDesign_tb/simulation/submodules/altera_up_av_config_serial_bus_controller.v"                                          -work AUDIO_CONFIG                                               -cdslib ./cds_libs/AUDIO_CONFIG.cds.lib                                              
  xmvlog $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS     "$QSYS_SIMDIR/MusicPlayerPlatformDesign_tb/simulation/submodules/altera_up_slow_clock_generator.v"                                                     -work AUDIO_CONFIG                                               -cdslib ./cds_libs/AUDIO_CONFIG.cds.lib                                              
  xmvlog $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS     "$QSYS_SIMDIR/MusicPlayerPlatformDesign_tb/simulation/submodules/altera_up_av_config_auto_init.v"                                                      -work AUDIO_CONFIG                                               -cdslib ./cds_libs/AUDIO_CONFIG.cds.lib                                              
  xmvlog $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS     "$QSYS_SIMDIR/MusicPlayerPlatformDesign_tb/simulation/submodules/altera_up_av_config_auto_init_dc2.v"                                                  -work AUDIO_CONFIG                                               -cdslib ./cds_libs/AUDIO_CONFIG.cds.lib                                              
  xmvlog $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS     "$QSYS_SIMDIR/MusicPlayerPlatformDesign_tb/simulation/submodules/altera_up_av_config_auto_init_d5m.v"                                                  -work AUDIO_CONFIG                                               -cdslib ./cds_libs/AUDIO_CONFIG.cds.lib                                              
  xmvlog $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS     "$QSYS_SIMDIR/MusicPlayerPlatformDesign_tb/simulation/submodules/altera_up_av_config_auto_init_lcm.v"                                                  -work AUDIO_CONFIG                                               -cdslib ./cds_libs/AUDIO_CONFIG.cds.lib                                              
  xmvlog $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS     "$QSYS_SIMDIR/MusicPlayerPlatformDesign_tb/simulation/submodules/altera_up_av_config_auto_init_ltm.v"                                                  -work AUDIO_CONFIG                                               -cdslib ./cds_libs/AUDIO_CONFIG.cds.lib                                              
  xmvlog $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS     "$QSYS_SIMDIR/MusicPlayerPlatformDesign_tb/simulation/submodules/altera_up_av_config_auto_init_ob_de1_soc.v"                                           -work AUDIO_CONFIG                                               -cdslib ./cds_libs/AUDIO_CONFIG.cds.lib                                              
  xmvlog $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS     "$QSYS_SIMDIR/MusicPlayerPlatformDesign_tb/simulation/submodules/altera_up_av_config_auto_init_ob_de2_115.v"                                           -work AUDIO_CONFIG                                               -cdslib ./cds_libs/AUDIO_CONFIG.cds.lib                                              
  xmvlog $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS     "$QSYS_SIMDIR/MusicPlayerPlatformDesign_tb/simulation/submodules/altera_up_av_config_auto_init_ob_de2i_150.v"                                          -work AUDIO_CONFIG                                               -cdslib ./cds_libs/AUDIO_CONFIG.cds.lib                                              
  xmvlog $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS     "$QSYS_SIMDIR/MusicPlayerPlatformDesign_tb/simulation/submodules/altera_up_av_config_auto_init_ob_de10_standard.v"                                     -work AUDIO_CONFIG                                               -cdslib ./cds_libs/AUDIO_CONFIG.cds.lib                                              
  xmvlog $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS     "$QSYS_SIMDIR/MusicPlayerPlatformDesign_tb/simulation/submodules/altera_up_av_config_auto_init_ob_audio.v"                                             -work AUDIO_CONFIG                                               -cdslib ./cds_libs/AUDIO_CONFIG.cds.lib                                              
  xmvlog $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS     "$QSYS_SIMDIR/MusicPlayerPlatformDesign_tb/simulation/submodules/altera_up_av_config_auto_init_ob_adv7180.v"                                           -work AUDIO_CONFIG                                               -cdslib ./cds_libs/AUDIO_CONFIG.cds.lib                                              
  xmvlog $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS     "$QSYS_SIMDIR/MusicPlayerPlatformDesign_tb/simulation/submodules/altera_up_av_config_auto_init_ob_adv7181.v"                                           -work AUDIO_CONFIG                                               -cdslib ./cds_libs/AUDIO_CONFIG.cds.lib                                              
  xmvlog $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS     "$QSYS_SIMDIR/MusicPlayerPlatformDesign_tb/simulation/submodules/MusicPlayerPlatformDesign_AUDIO_CONFIG.v"                                             -work AUDIO_CONFIG                                               -cdslib ./cds_libs/AUDIO_CONFIG.cds.lib                                              
  xmvlog -sv $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/MusicPlayerPlatformDesign_tb/simulation/submodules/altera_conduit_bfm_0007.sv"                                                           -work MusicPlayerPlatformDesign_inst_vga_outputs_bfm             -cdslib ./cds_libs/MusicPlayerPlatformDesign_inst_vga_outputs_bfm.cds.lib            
  xmvlog -sv $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/MusicPlayerPlatformDesign_tb/simulation/submodules/altera_conduit_bfm_0006.sv"                                                           -work MusicPlayerPlatformDesign_inst_timer_status_input_bfm      -cdslib ./cds_libs/MusicPlayerPlatformDesign_inst_timer_status_input_bfm.cds.lib     
  xmvlog -sv $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/MusicPlayerPlatformDesign_tb/simulation/submodules/altera_conduit_bfm_0005.sv"                                                           -work MusicPlayerPlatformDesign_inst_timer_ctrl_output_bfm       -cdslib ./cds_libs/MusicPlayerPlatformDesign_inst_timer_ctrl_output_bfm.cds.lib      
  xmvlog -sv $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/MusicPlayerPlatformDesign_tb/simulation/submodules/altera_conduit_bfm_0004.sv"                                                           -work MusicPlayerPlatformDesign_inst_switch_input_bfm            -cdslib ./cds_libs/MusicPlayerPlatformDesign_inst_switch_input_bfm.cds.lib           
  xmvlog -sv $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/MusicPlayerPlatformDesign_tb/simulation/submodules/altera_avalon_reset_source.sv"                                                        -work MusicPlayerPlatformDesign_inst_reset_bfm                   -cdslib ./cds_libs/MusicPlayerPlatformDesign_inst_reset_bfm.cds.lib                  
  xmvlog -sv $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/MusicPlayerPlatformDesign_tb/simulation/submodules/altera_avalon_clock_source.sv"                                                        -work MusicPlayerPlatformDesign_inst_clk_bfm                     -cdslib ./cds_libs/MusicPlayerPlatformDesign_inst_clk_bfm.cds.lib                    
  xmvlog -sv $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/MusicPlayerPlatformDesign_tb/simulation/submodules/altera_conduit_bfm_0003.sv"                                                           -work MusicPlayerPlatformDesign_inst_buttons_input_bfm           -cdslib ./cds_libs/MusicPlayerPlatformDesign_inst_buttons_input_bfm.cds.lib          
  xmvlog -sv $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/MusicPlayerPlatformDesign_tb/simulation/submodules/altera_conduit_bfm_0002.sv"                                                           -work MusicPlayerPlatformDesign_inst_audio_export_bfm            -cdslib ./cds_libs/MusicPlayerPlatformDesign_inst_audio_export_bfm.cds.lib           
  xmvlog -sv $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/MusicPlayerPlatformDesign_tb/simulation/submodules/altera_conduit_bfm.sv"                                                                -work MusicPlayerPlatformDesign_inst_audio_config_export_bfm     -cdslib ./cds_libs/MusicPlayerPlatformDesign_inst_audio_config_export_bfm.cds.lib    
  xmvlog $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS     "$QSYS_SIMDIR/MusicPlayerPlatformDesign_tb/simulation/submodules/MusicPlayerPlatformDesign.v"                                                          -work MusicPlayerPlatformDesign_inst                             -cdslib ./cds_libs/MusicPlayerPlatformDesign_inst.cds.lib                            
  xmvlog $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS     "$QSYS_SIMDIR/MusicPlayerPlatformDesign_tb/simulation/MusicPlayerPlatformDesign_tb.v"                                                                                                                                                                                                                        
fi

# ----------------------------------------
# elaborate top level design
if [ $SKIP_ELAB -eq 0 ]; then
  xmelab -update -access +w+r+c -namemap_mixgen +DISABLEGENCHK $ELAB_OPTIONS $USER_DEFINED_ELAB_OPTIONS $TOP_LEVEL_NAME
fi

# ----------------------------------------
# simulate
if [ $SKIP_SIM -eq 0 ]; then
  eval xmsim -licqueue $SIM_OPTIONS $USER_DEFINED_SIM_OPTIONS $TOP_LEVEL_NAME
fi
