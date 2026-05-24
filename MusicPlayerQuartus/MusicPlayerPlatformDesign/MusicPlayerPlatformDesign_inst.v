	MusicPlayerPlatformDesign u0 (
		.audio_config_export_SDAT  (<connected-to-audio_config_export_SDAT>),  // audio_config_export.SDAT
		.audio_config_export_SCLK  (<connected-to-audio_config_export_SCLK>),  //                    .SCLK
		.audio_export_BCLK         (<connected-to-audio_export_BCLK>),         //        audio_export.BCLK
		.audio_export_DACDAT       (<connected-to-audio_export_DACDAT>),       //                    .DACDAT
		.audio_export_DACLRCK      (<connected-to-audio_export_DACLRCK>),      //                    .DACLRCK
		.buttons_input_export      (<connected-to-buttons_input_export>),      //       buttons_input.export
		.clk_clk                   (<connected-to-clk_clk>),                   //                 clk.clk
		.reset_reset_n             (<connected-to-reset_reset_n>),             //               reset.reset_n
		.switch_input_export       (<connected-to-switch_input_export>),       //        switch_input.export
		.timer_ctrl_output_export  (<connected-to-timer_ctrl_output_export>),  //   timer_ctrl_output.export
		.timer_status_input_export (<connected-to-timer_status_input_export>), //  timer_status_input.export
		.vga_clk_clk               (<connected-to-vga_clk_clk>),               //             vga_clk.clk
		.vga_outputs_CLK           (<connected-to-vga_outputs_CLK>),           //         vga_outputs.CLK
		.vga_outputs_HS            (<connected-to-vga_outputs_HS>),            //                    .HS
		.vga_outputs_VS            (<connected-to-vga_outputs_VS>),            //                    .VS
		.vga_outputs_BLANK         (<connected-to-vga_outputs_BLANK>),         //                    .BLANK
		.vga_outputs_SYNC          (<connected-to-vga_outputs_SYNC>),          //                    .SYNC
		.vga_outputs_R             (<connected-to-vga_outputs_R>),             //                    .R
		.vga_outputs_G             (<connected-to-vga_outputs_G>),             //                    .G
		.vga_outputs_B             (<connected-to-vga_outputs_B>)              //                    .B
	);

