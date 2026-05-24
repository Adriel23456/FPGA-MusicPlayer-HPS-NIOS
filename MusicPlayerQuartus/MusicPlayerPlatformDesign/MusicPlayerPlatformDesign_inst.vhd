	component MusicPlayerPlatformDesign is
		port (
			audio_config_export_SDAT  : inout std_logic                    := 'X';             -- SDAT
			audio_config_export_SCLK  : out   std_logic;                                       -- SCLK
			audio_export_BCLK         : in    std_logic                    := 'X';             -- BCLK
			audio_export_DACDAT       : out   std_logic;                                       -- DACDAT
			audio_export_DACLRCK      : in    std_logic                    := 'X';             -- DACLRCK
			buttons_input_export      : in    std_logic_vector(3 downto 0) := (others => 'X'); -- export
			clk_clk                   : in    std_logic                    := 'X';             -- clk
			reset_reset_n             : in    std_logic                    := 'X';             -- reset_n
			switch_input_export       : in    std_logic                    := 'X';             -- export
			timer_ctrl_output_export  : out   std_logic_vector(1 downto 0);                    -- export
			timer_status_input_export : in    std_logic_vector(1 downto 0) := (others => 'X'); -- export
			vga_clk_clk               : in    std_logic                    := 'X';             -- clk
			vga_outputs_CLK           : out   std_logic;                                       -- CLK
			vga_outputs_HS            : out   std_logic;                                       -- HS
			vga_outputs_VS            : out   std_logic;                                       -- VS
			vga_outputs_BLANK         : out   std_logic;                                       -- BLANK
			vga_outputs_SYNC          : out   std_logic;                                       -- SYNC
			vga_outputs_R             : out   std_logic_vector(7 downto 0);                    -- R
			vga_outputs_G             : out   std_logic_vector(7 downto 0);                    -- G
			vga_outputs_B             : out   std_logic_vector(7 downto 0)                     -- B
		);
	end component MusicPlayerPlatformDesign;

	u0 : component MusicPlayerPlatformDesign
		port map (
			audio_config_export_SDAT  => CONNECTED_TO_audio_config_export_SDAT,  -- audio_config_export.SDAT
			audio_config_export_SCLK  => CONNECTED_TO_audio_config_export_SCLK,  --                    .SCLK
			audio_export_BCLK         => CONNECTED_TO_audio_export_BCLK,         --        audio_export.BCLK
			audio_export_DACDAT       => CONNECTED_TO_audio_export_DACDAT,       --                    .DACDAT
			audio_export_DACLRCK      => CONNECTED_TO_audio_export_DACLRCK,      --                    .DACLRCK
			buttons_input_export      => CONNECTED_TO_buttons_input_export,      --       buttons_input.export
			clk_clk                   => CONNECTED_TO_clk_clk,                   --                 clk.clk
			reset_reset_n             => CONNECTED_TO_reset_reset_n,             --               reset.reset_n
			switch_input_export       => CONNECTED_TO_switch_input_export,       --        switch_input.export
			timer_ctrl_output_export  => CONNECTED_TO_timer_ctrl_output_export,  --   timer_ctrl_output.export
			timer_status_input_export => CONNECTED_TO_timer_status_input_export, --  timer_status_input.export
			vga_clk_clk               => CONNECTED_TO_vga_clk_clk,               --             vga_clk.clk
			vga_outputs_CLK           => CONNECTED_TO_vga_outputs_CLK,           --         vga_outputs.CLK
			vga_outputs_HS            => CONNECTED_TO_vga_outputs_HS,            --                    .HS
			vga_outputs_VS            => CONNECTED_TO_vga_outputs_VS,            --                    .VS
			vga_outputs_BLANK         => CONNECTED_TO_vga_outputs_BLANK,         --                    .BLANK
			vga_outputs_SYNC          => CONNECTED_TO_vga_outputs_SYNC,          --                    .SYNC
			vga_outputs_R             => CONNECTED_TO_vga_outputs_R,             --                    .R
			vga_outputs_G             => CONNECTED_TO_vga_outputs_G,             --                    .G
			vga_outputs_B             => CONNECTED_TO_vga_outputs_B              --                    .B
		);

