	component MusicPlayerPlatformDesign is
		port (
			audio_config_export_SDAT          : inout std_logic                     := 'X';             -- SDAT
			audio_config_export_SCLK          : out   std_logic;                                        -- SCLK
			audio_export_BCLK                 : in    std_logic                     := 'X';             -- BCLK
			audio_export_DACDAT               : out   std_logic;                                        -- DACDAT
			audio_export_DACLRCK              : in    std_logic                     := 'X';             -- DACLRCK
			buttons_input_export              : in    std_logic_vector(3 downto 0)  := (others => 'X'); -- export
			clk_clk                           : in    std_logic                     := 'X';             -- clk
			reset_reset_n                     : in    std_logic                     := 'X';             -- reset_n
			switch_input_export               : in    std_logic                     := 'X';             -- export
			timer_ctrl_output_export          : out   std_logic_vector(1 downto 0);                     -- export
			timer_status_input_export         : in    std_logic_vector(1 downto 0)  := (others => 'X'); -- export
			vga_clk_clk                       : in    std_logic                     := 'X';             -- clk
			vga_outputs_CLK                   : out   std_logic;                                        -- CLK
			vga_outputs_HS                    : out   std_logic;                                        -- HS
			vga_outputs_VS                    : out   std_logic;                                        -- VS
			vga_outputs_BLANK                 : out   std_logic;                                        -- BLANK
			vga_outputs_SYNC                  : out   std_logic;                                        -- SYNC
			vga_outputs_R                     : out   std_logic_vector(7 downto 0);                     -- R
			vga_outputs_G                     : out   std_logic_vector(7 downto 0);                     -- G
			vga_outputs_B                     : out   std_logic_vector(7 downto 0);                     -- B
			hps_io_hps_io_emac0_inst_TX_CLK   : out   std_logic;                                        -- hps_io_emac0_inst_TX_CLK
			hps_io_hps_io_emac0_inst_TXD0     : out   std_logic;                                        -- hps_io_emac0_inst_TXD0
			hps_io_hps_io_emac0_inst_TXD1     : out   std_logic;                                        -- hps_io_emac0_inst_TXD1
			hps_io_hps_io_emac0_inst_TXD2     : out   std_logic;                                        -- hps_io_emac0_inst_TXD2
			hps_io_hps_io_emac0_inst_TXD3     : out   std_logic;                                        -- hps_io_emac0_inst_TXD3
			hps_io_hps_io_emac0_inst_RXD0     : in    std_logic                     := 'X';             -- hps_io_emac0_inst_RXD0
			hps_io_hps_io_emac0_inst_MDIO     : inout std_logic                     := 'X';             -- hps_io_emac0_inst_MDIO
			hps_io_hps_io_emac0_inst_MDC      : out   std_logic;                                        -- hps_io_emac0_inst_MDC
			hps_io_hps_io_emac0_inst_RX_CTL   : in    std_logic                     := 'X';             -- hps_io_emac0_inst_RX_CTL
			hps_io_hps_io_emac0_inst_TX_CTL   : out   std_logic;                                        -- hps_io_emac0_inst_TX_CTL
			hps_io_hps_io_emac0_inst_RX_CLK   : in    std_logic                     := 'X';             -- hps_io_emac0_inst_RX_CLK
			hps_io_hps_io_emac0_inst_RXD1     : in    std_logic                     := 'X';             -- hps_io_emac0_inst_RXD1
			hps_io_hps_io_emac0_inst_RXD2     : in    std_logic                     := 'X';             -- hps_io_emac0_inst_RXD2
			hps_io_hps_io_emac0_inst_RXD3     : in    std_logic                     := 'X';             -- hps_io_emac0_inst_RXD3
			hps_io_hps_io_sdio_inst_CMD       : inout std_logic                     := 'X';             -- hps_io_sdio_inst_CMD
			hps_io_hps_io_sdio_inst_D0        : inout std_logic                     := 'X';             -- hps_io_sdio_inst_D0
			hps_io_hps_io_sdio_inst_D1        : inout std_logic                     := 'X';             -- hps_io_sdio_inst_D1
			hps_io_hps_io_sdio_inst_CLK       : out   std_logic;                                        -- hps_io_sdio_inst_CLK
			hps_io_hps_io_sdio_inst_D2        : inout std_logic                     := 'X';             -- hps_io_sdio_inst_D2
			hps_io_hps_io_sdio_inst_D3        : inout std_logic                     := 'X';             -- hps_io_sdio_inst_D3
			memory_mem_a                      : out   std_logic_vector(12 downto 0);                    -- mem_a
			memory_mem_ba                     : out   std_logic_vector(2 downto 0);                     -- mem_ba
			memory_mem_ck                     : out   std_logic;                                        -- mem_ck
			memory_mem_ck_n                   : out   std_logic;                                        -- mem_ck_n
			memory_mem_cke                    : out   std_logic;                                        -- mem_cke
			memory_mem_cs_n                   : out   std_logic;                                        -- mem_cs_n
			memory_mem_ras_n                  : out   std_logic;                                        -- mem_ras_n
			memory_mem_cas_n                  : out   std_logic;                                        -- mem_cas_n
			memory_mem_we_n                   : out   std_logic;                                        -- mem_we_n
			memory_mem_reset_n                : out   std_logic;                                        -- mem_reset_n
			memory_mem_dq                     : inout std_logic_vector(7 downto 0)  := (others => 'X'); -- mem_dq
			memory_mem_dqs                    : inout std_logic                     := 'X';             -- mem_dqs
			memory_mem_dqs_n                  : inout std_logic                     := 'X';             -- mem_dqs_n
			memory_mem_odt                    : out   std_logic;                                        -- mem_odt
			memory_mem_dm                     : out   std_logic;                                        -- mem_dm
			memory_oct_rzqin                  : in    std_logic                     := 'X';             -- oct_rzqin
			hps_arm_h2f_mpu_events_eventi     : in    std_logic                     := 'X';             -- eventi
			hps_arm_h2f_mpu_events_evento     : out   std_logic;                                        -- evento
			hps_arm_h2f_mpu_events_standbywfe : out   std_logic_vector(1 downto 0);                     -- standbywfe
			hps_arm_h2f_mpu_events_standbywfi : out   std_logic_vector(1 downto 0);                     -- standbywfi
			audio_clk_export_clk              : out   std_logic                                         -- clk
		);
	end component MusicPlayerPlatformDesign;

	u0 : component MusicPlayerPlatformDesign
		port map (
			audio_config_export_SDAT          => CONNECTED_TO_audio_config_export_SDAT,          --    audio_config_export.SDAT
			audio_config_export_SCLK          => CONNECTED_TO_audio_config_export_SCLK,          --                       .SCLK
			audio_export_BCLK                 => CONNECTED_TO_audio_export_BCLK,                 --           audio_export.BCLK
			audio_export_DACDAT               => CONNECTED_TO_audio_export_DACDAT,               --                       .DACDAT
			audio_export_DACLRCK              => CONNECTED_TO_audio_export_DACLRCK,              --                       .DACLRCK
			buttons_input_export              => CONNECTED_TO_buttons_input_export,              --          buttons_input.export
			clk_clk                           => CONNECTED_TO_clk_clk,                           --                    clk.clk
			reset_reset_n                     => CONNECTED_TO_reset_reset_n,                     --                  reset.reset_n
			switch_input_export               => CONNECTED_TO_switch_input_export,               --           switch_input.export
			timer_ctrl_output_export          => CONNECTED_TO_timer_ctrl_output_export,          --      timer_ctrl_output.export
			timer_status_input_export         => CONNECTED_TO_timer_status_input_export,         --     timer_status_input.export
			vga_clk_clk                       => CONNECTED_TO_vga_clk_clk,                       --                vga_clk.clk
			vga_outputs_CLK                   => CONNECTED_TO_vga_outputs_CLK,                   --            vga_outputs.CLK
			vga_outputs_HS                    => CONNECTED_TO_vga_outputs_HS,                    --                       .HS
			vga_outputs_VS                    => CONNECTED_TO_vga_outputs_VS,                    --                       .VS
			vga_outputs_BLANK                 => CONNECTED_TO_vga_outputs_BLANK,                 --                       .BLANK
			vga_outputs_SYNC                  => CONNECTED_TO_vga_outputs_SYNC,                  --                       .SYNC
			vga_outputs_R                     => CONNECTED_TO_vga_outputs_R,                     --                       .R
			vga_outputs_G                     => CONNECTED_TO_vga_outputs_G,                     --                       .G
			vga_outputs_B                     => CONNECTED_TO_vga_outputs_B,                     --                       .B
			hps_io_hps_io_emac0_inst_TX_CLK   => CONNECTED_TO_hps_io_hps_io_emac0_inst_TX_CLK,   --                 hps_io.hps_io_emac0_inst_TX_CLK
			hps_io_hps_io_emac0_inst_TXD0     => CONNECTED_TO_hps_io_hps_io_emac0_inst_TXD0,     --                       .hps_io_emac0_inst_TXD0
			hps_io_hps_io_emac0_inst_TXD1     => CONNECTED_TO_hps_io_hps_io_emac0_inst_TXD1,     --                       .hps_io_emac0_inst_TXD1
			hps_io_hps_io_emac0_inst_TXD2     => CONNECTED_TO_hps_io_hps_io_emac0_inst_TXD2,     --                       .hps_io_emac0_inst_TXD2
			hps_io_hps_io_emac0_inst_TXD3     => CONNECTED_TO_hps_io_hps_io_emac0_inst_TXD3,     --                       .hps_io_emac0_inst_TXD3
			hps_io_hps_io_emac0_inst_RXD0     => CONNECTED_TO_hps_io_hps_io_emac0_inst_RXD0,     --                       .hps_io_emac0_inst_RXD0
			hps_io_hps_io_emac0_inst_MDIO     => CONNECTED_TO_hps_io_hps_io_emac0_inst_MDIO,     --                       .hps_io_emac0_inst_MDIO
			hps_io_hps_io_emac0_inst_MDC      => CONNECTED_TO_hps_io_hps_io_emac0_inst_MDC,      --                       .hps_io_emac0_inst_MDC
			hps_io_hps_io_emac0_inst_RX_CTL   => CONNECTED_TO_hps_io_hps_io_emac0_inst_RX_CTL,   --                       .hps_io_emac0_inst_RX_CTL
			hps_io_hps_io_emac0_inst_TX_CTL   => CONNECTED_TO_hps_io_hps_io_emac0_inst_TX_CTL,   --                       .hps_io_emac0_inst_TX_CTL
			hps_io_hps_io_emac0_inst_RX_CLK   => CONNECTED_TO_hps_io_hps_io_emac0_inst_RX_CLK,   --                       .hps_io_emac0_inst_RX_CLK
			hps_io_hps_io_emac0_inst_RXD1     => CONNECTED_TO_hps_io_hps_io_emac0_inst_RXD1,     --                       .hps_io_emac0_inst_RXD1
			hps_io_hps_io_emac0_inst_RXD2     => CONNECTED_TO_hps_io_hps_io_emac0_inst_RXD2,     --                       .hps_io_emac0_inst_RXD2
			hps_io_hps_io_emac0_inst_RXD3     => CONNECTED_TO_hps_io_hps_io_emac0_inst_RXD3,     --                       .hps_io_emac0_inst_RXD3
			hps_io_hps_io_sdio_inst_CMD       => CONNECTED_TO_hps_io_hps_io_sdio_inst_CMD,       --                       .hps_io_sdio_inst_CMD
			hps_io_hps_io_sdio_inst_D0        => CONNECTED_TO_hps_io_hps_io_sdio_inst_D0,        --                       .hps_io_sdio_inst_D0
			hps_io_hps_io_sdio_inst_D1        => CONNECTED_TO_hps_io_hps_io_sdio_inst_D1,        --                       .hps_io_sdio_inst_D1
			hps_io_hps_io_sdio_inst_CLK       => CONNECTED_TO_hps_io_hps_io_sdio_inst_CLK,       --                       .hps_io_sdio_inst_CLK
			hps_io_hps_io_sdio_inst_D2        => CONNECTED_TO_hps_io_hps_io_sdio_inst_D2,        --                       .hps_io_sdio_inst_D2
			hps_io_hps_io_sdio_inst_D3        => CONNECTED_TO_hps_io_hps_io_sdio_inst_D3,        --                       .hps_io_sdio_inst_D3
			memory_mem_a                      => CONNECTED_TO_memory_mem_a,                      --                 memory.mem_a
			memory_mem_ba                     => CONNECTED_TO_memory_mem_ba,                     --                       .mem_ba
			memory_mem_ck                     => CONNECTED_TO_memory_mem_ck,                     --                       .mem_ck
			memory_mem_ck_n                   => CONNECTED_TO_memory_mem_ck_n,                   --                       .mem_ck_n
			memory_mem_cke                    => CONNECTED_TO_memory_mem_cke,                    --                       .mem_cke
			memory_mem_cs_n                   => CONNECTED_TO_memory_mem_cs_n,                   --                       .mem_cs_n
			memory_mem_ras_n                  => CONNECTED_TO_memory_mem_ras_n,                  --                       .mem_ras_n
			memory_mem_cas_n                  => CONNECTED_TO_memory_mem_cas_n,                  --                       .mem_cas_n
			memory_mem_we_n                   => CONNECTED_TO_memory_mem_we_n,                   --                       .mem_we_n
			memory_mem_reset_n                => CONNECTED_TO_memory_mem_reset_n,                --                       .mem_reset_n
			memory_mem_dq                     => CONNECTED_TO_memory_mem_dq,                     --                       .mem_dq
			memory_mem_dqs                    => CONNECTED_TO_memory_mem_dqs,                    --                       .mem_dqs
			memory_mem_dqs_n                  => CONNECTED_TO_memory_mem_dqs_n,                  --                       .mem_dqs_n
			memory_mem_odt                    => CONNECTED_TO_memory_mem_odt,                    --                       .mem_odt
			memory_mem_dm                     => CONNECTED_TO_memory_mem_dm,                     --                       .mem_dm
			memory_oct_rzqin                  => CONNECTED_TO_memory_oct_rzqin,                  --                       .oct_rzqin
			hps_arm_h2f_mpu_events_eventi     => CONNECTED_TO_hps_arm_h2f_mpu_events_eventi,     -- hps_arm_h2f_mpu_events.eventi
			hps_arm_h2f_mpu_events_evento     => CONNECTED_TO_hps_arm_h2f_mpu_events_evento,     --                       .evento
			hps_arm_h2f_mpu_events_standbywfe => CONNECTED_TO_hps_arm_h2f_mpu_events_standbywfe, --                       .standbywfe
			hps_arm_h2f_mpu_events_standbywfi => CONNECTED_TO_hps_arm_h2f_mpu_events_standbywfi, --                       .standbywfi
			audio_clk_export_clk              => CONNECTED_TO_audio_clk_export_clk               --       audio_clk_export.clk
		);

