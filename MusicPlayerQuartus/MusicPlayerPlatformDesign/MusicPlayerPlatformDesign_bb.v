
module MusicPlayerPlatformDesign (
	audio_config_export_SDAT,
	audio_config_export_SCLK,
	audio_export_BCLK,
	audio_export_DACDAT,
	audio_export_DACLRCK,
	buttons_input_export,
	clk_clk,
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

	inout		audio_config_export_SDAT;
	output		audio_config_export_SCLK;
	input		audio_export_BCLK;
	output		audio_export_DACDAT;
	input		audio_export_DACLRCK;
	input	[3:0]	buttons_input_export;
	input		clk_clk;
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
