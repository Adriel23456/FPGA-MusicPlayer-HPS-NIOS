
module MusicPlayerPlatformDesign (
	audio_clk_export_clk,
	audio_config_export_SDAT,
	audio_config_export_SCLK,
	audio_config_raw_SDAT,
	audio_config_raw_SCLK,
	audio_export_BCLK,
	audio_export_DACDAT,
	audio_export_DACLRCK,
	audio_raw_BCLK,
	audio_raw_DACDAT,
	audio_raw_DACLRCK,
	buttons_input_export,
	clk_clk,
	config_pd_export,
	filter_pd_bclk,
	filter_pd_daclrck,
	filter_pd_dacdat,
	filter_select_filter_sw,
	hps_arm_h2f_mpu_events_eventi,
	hps_arm_h2f_mpu_events_evento,
	hps_arm_h2f_mpu_events_standbywfe,
	hps_arm_h2f_mpu_events_standbywfi,
	hps_io_hps_io_emac0_inst_TX_CLK,
	hps_io_hps_io_emac0_inst_TXD0,
	hps_io_hps_io_emac0_inst_TXD1,
	hps_io_hps_io_emac0_inst_TXD2,
	hps_io_hps_io_emac0_inst_TXD3,
	hps_io_hps_io_emac0_inst_RXD0,
	hps_io_hps_io_emac0_inst_MDIO,
	hps_io_hps_io_emac0_inst_MDC,
	hps_io_hps_io_emac0_inst_RX_CTL,
	hps_io_hps_io_emac0_inst_TX_CTL,
	hps_io_hps_io_emac0_inst_RX_CLK,
	hps_io_hps_io_emac0_inst_RXD1,
	hps_io_hps_io_emac0_inst_RXD2,
	hps_io_hps_io_emac0_inst_RXD3,
	hps_io_hps_io_sdio_inst_CMD,
	hps_io_hps_io_sdio_inst_D0,
	hps_io_hps_io_sdio_inst_D1,
	hps_io_hps_io_sdio_inst_CLK,
	hps_io_hps_io_sdio_inst_D2,
	hps_io_hps_io_sdio_inst_D3,
	memory_mem_a,
	memory_mem_ba,
	memory_mem_ck,
	memory_mem_ck_n,
	memory_mem_cke,
	memory_mem_cs_n,
	memory_mem_ras_n,
	memory_mem_cas_n,
	memory_mem_we_n,
	memory_mem_reset_n,
	memory_mem_dq,
	memory_mem_dqs,
	memory_mem_dqs_n,
	memory_mem_odt,
	memory_mem_dm,
	memory_oct_rzqin,
	reset_reset_n,
	switch_input_export,
	timer_ctrl_output_export,
	timer_status_input_export,
	vga_clk_clk,
	vga_outputs_CLK,
	vga_outputs_HS,
	vga_outputs_VS,
	vga_outputs_BLANK,
	vga_outputs_SYNC,
	vga_outputs_R,
	vga_outputs_G,
	vga_outputs_B);	

	output		audio_clk_export_clk;
	inout		audio_config_export_SDAT;
	output		audio_config_export_SCLK;
	inout		audio_config_raw_SDAT;
	output		audio_config_raw_SCLK;
	input		audio_export_BCLK;
	output		audio_export_DACDAT;
	input		audio_export_DACLRCK;
	input		audio_raw_BCLK;
	output		audio_raw_DACDAT;
	input		audio_raw_DACLRCK;
	input	[3:0]	buttons_input_export;
	input		clk_clk;
	input		config_pd_export;
	output		filter_pd_bclk;
	output		filter_pd_daclrck;
	input		filter_pd_dacdat;
	input	[1:0]	filter_select_filter_sw;
	input		hps_arm_h2f_mpu_events_eventi;
	output		hps_arm_h2f_mpu_events_evento;
	output	[1:0]	hps_arm_h2f_mpu_events_standbywfe;
	output	[1:0]	hps_arm_h2f_mpu_events_standbywfi;
	output		hps_io_hps_io_emac0_inst_TX_CLK;
	output		hps_io_hps_io_emac0_inst_TXD0;
	output		hps_io_hps_io_emac0_inst_TXD1;
	output		hps_io_hps_io_emac0_inst_TXD2;
	output		hps_io_hps_io_emac0_inst_TXD3;
	input		hps_io_hps_io_emac0_inst_RXD0;
	inout		hps_io_hps_io_emac0_inst_MDIO;
	output		hps_io_hps_io_emac0_inst_MDC;
	input		hps_io_hps_io_emac0_inst_RX_CTL;
	output		hps_io_hps_io_emac0_inst_TX_CTL;
	input		hps_io_hps_io_emac0_inst_RX_CLK;
	input		hps_io_hps_io_emac0_inst_RXD1;
	input		hps_io_hps_io_emac0_inst_RXD2;
	input		hps_io_hps_io_emac0_inst_RXD3;
	inout		hps_io_hps_io_sdio_inst_CMD;
	inout		hps_io_hps_io_sdio_inst_D0;
	inout		hps_io_hps_io_sdio_inst_D1;
	output		hps_io_hps_io_sdio_inst_CLK;
	inout		hps_io_hps_io_sdio_inst_D2;
	inout		hps_io_hps_io_sdio_inst_D3;
	output	[12:0]	memory_mem_a;
	output	[2:0]	memory_mem_ba;
	output		memory_mem_ck;
	output		memory_mem_ck_n;
	output		memory_mem_cke;
	output		memory_mem_cs_n;
	output		memory_mem_ras_n;
	output		memory_mem_cas_n;
	output		memory_mem_we_n;
	output		memory_mem_reset_n;
	inout	[7:0]	memory_mem_dq;
	inout		memory_mem_dqs;
	inout		memory_mem_dqs_n;
	output		memory_mem_odt;
	output		memory_mem_dm;
	input		memory_oct_rzqin;
	input		reset_reset_n;
	input		switch_input_export;
	output	[1:0]	timer_ctrl_output_export;
	input	[1:0]	timer_status_input_export;
	input		vga_clk_clk;
	output		vga_outputs_CLK;
	output		vga_outputs_HS;
	output		vga_outputs_VS;
	output		vga_outputs_BLANK;
	output		vga_outputs_SYNC;
	output	[7:0]	vga_outputs_R;
	output	[7:0]	vga_outputs_G;
	output	[7:0]	vga_outputs_B;
endmodule
