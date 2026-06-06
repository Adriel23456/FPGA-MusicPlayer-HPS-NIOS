/*
 * system.h - SOPC Builder system and BSP software package information
 *
 * Machine generated for CPU 'CPU_NIOS_II' in SOPC Builder design 'MusicPlayerPlatformDesign'
 * SOPC Builder design path: /media/adriel/Extra/Escritorio/FPGA-MusicPlayer-HPS-NIOS/MusicPlayerQuartus22/MusicPlayerPlatformDesign.sopcinfo
 *
 * Generated: Sat Jun 06 05:26:00 CST 2026
 */

/*
 * DO NOT MODIFY THIS FILE
 *
 * Changing this file will have subtle consequences
 * which will almost certainly lead to a nonfunctioning
 * system. If you do modify this file, be aware that your
 * changes will be overwritten and lost when this file
 * is generated again.
 *
 * DO NOT MODIFY THIS FILE
 */

/*
 * License Agreement
 *
 * Copyright (c) 2008
 * Altera Corporation, San Jose, California, USA.
 * All rights reserved.
 *
 * Permission is hereby granted, free of charge, to any person obtaining a
 * copy of this software and associated documentation files (the "Software"),
 * to deal in the Software without restriction, including without limitation
 * the rights to use, copy, modify, merge, publish, distribute, sublicense,
 * and/or sell copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 * DEALINGS IN THE SOFTWARE.
 *
 * This agreement shall be governed in all respects by the laws of the State
 * of California and by the laws of the United States of America.
 */

#ifndef __SYSTEM_H_
#define __SYSTEM_H_

/* Include definitions from linker script generator */
#include "linker.h"


/*
 * AUDIO_CONFIG configuration
 *
 */

#define ALT_MODULE_CLASS_AUDIO_CONFIG altera_up_avalon_audio_and_video_config
#define AUDIO_CONFIG_BASE 0x13040
#define AUDIO_CONFIG_IRQ -1
#define AUDIO_CONFIG_IRQ_INTERRUPT_CONTROLLER_ID -1
#define AUDIO_CONFIG_NAME "/dev/AUDIO_CONFIG"
#define AUDIO_CONFIG_SPAN 16
#define AUDIO_CONFIG_TYPE "altera_up_avalon_audio_and_video_config"


/*
 * AUDIO_OUT configuration
 *
 */

#define ALT_MODULE_CLASS_AUDIO_OUT altera_up_avalon_audio
#define AUDIO_OUT_BASE 0x13050
#define AUDIO_OUT_IRQ 3
#define AUDIO_OUT_IRQ_INTERRUPT_CONTROLLER_ID 0
#define AUDIO_OUT_NAME "/dev/AUDIO_OUT"
#define AUDIO_OUT_SPAN 16
#define AUDIO_OUT_TYPE "altera_up_avalon_audio"


/*
 * CPU configuration
 *
 */

#define ALT_CPU_ARCHITECTURE "altera_nios2_gen2"
#define ALT_CPU_BIG_ENDIAN 0
#define ALT_CPU_BREAK_ADDR 0x00012820
#define ALT_CPU_CPU_ARCH_NIOS2_R1
#define ALT_CPU_CPU_FREQ 50000000u
#define ALT_CPU_CPU_ID_SIZE 1
#define ALT_CPU_CPU_ID_VALUE 0x00000000
#define ALT_CPU_CPU_IMPLEMENTATION "tiny"
#define ALT_CPU_DATA_ADDR_WIDTH 0x11
#define ALT_CPU_DCACHE_LINE_SIZE 0
#define ALT_CPU_DCACHE_LINE_SIZE_LOG2 0
#define ALT_CPU_DCACHE_SIZE 0
#define ALT_CPU_EXCEPTION_ADDR 0x00008020
#define ALT_CPU_FLASH_ACCELERATOR_LINES 0
#define ALT_CPU_FLASH_ACCELERATOR_LINE_SIZE 0
#define ALT_CPU_FLUSHDA_SUPPORTED
#define ALT_CPU_FREQ 50000000
#define ALT_CPU_HARDWARE_DIVIDE_PRESENT 0
#define ALT_CPU_HARDWARE_MULTIPLY_PRESENT 0
#define ALT_CPU_HARDWARE_MULX_PRESENT 0
#define ALT_CPU_HAS_DEBUG_CORE 1
#define ALT_CPU_HAS_DEBUG_STUB
#define ALT_CPU_HAS_ILLEGAL_INSTRUCTION_EXCEPTION
#define ALT_CPU_HAS_JMPI_INSTRUCTION
#define ALT_CPU_ICACHE_LINE_SIZE 0
#define ALT_CPU_ICACHE_LINE_SIZE_LOG2 0
#define ALT_CPU_ICACHE_SIZE 0
#define ALT_CPU_INST_ADDR_WIDTH 0x11
#define ALT_CPU_NAME "CPU_NIOS_II"
#define ALT_CPU_OCI_VERSION 1
#define ALT_CPU_RESET_ADDR 0x00008000


/*
 * CPU configuration (with legacy prefix - don't use these anymore)
 *
 */

#define NIOS2_BIG_ENDIAN 0
#define NIOS2_BREAK_ADDR 0x00012820
#define NIOS2_CPU_ARCH_NIOS2_R1
#define NIOS2_CPU_FREQ 50000000u
#define NIOS2_CPU_ID_SIZE 1
#define NIOS2_CPU_ID_VALUE 0x00000000
#define NIOS2_CPU_IMPLEMENTATION "tiny"
#define NIOS2_DATA_ADDR_WIDTH 0x11
#define NIOS2_DCACHE_LINE_SIZE 0
#define NIOS2_DCACHE_LINE_SIZE_LOG2 0
#define NIOS2_DCACHE_SIZE 0
#define NIOS2_EXCEPTION_ADDR 0x00008020
#define NIOS2_FLASH_ACCELERATOR_LINES 0
#define NIOS2_FLASH_ACCELERATOR_LINE_SIZE 0
#define NIOS2_FLUSHDA_SUPPORTED
#define NIOS2_HARDWARE_DIVIDE_PRESENT 0
#define NIOS2_HARDWARE_MULTIPLY_PRESENT 0
#define NIOS2_HARDWARE_MULX_PRESENT 0
#define NIOS2_HAS_DEBUG_CORE 1
#define NIOS2_HAS_DEBUG_STUB
#define NIOS2_HAS_ILLEGAL_INSTRUCTION_EXCEPTION
#define NIOS2_HAS_JMPI_INSTRUCTION
#define NIOS2_ICACHE_LINE_SIZE 0
#define NIOS2_ICACHE_LINE_SIZE_LOG2 0
#define NIOS2_ICACHE_SIZE 0
#define NIOS2_INST_ADDR_WIDTH 0x11
#define NIOS2_OCI_VERSION 1
#define NIOS2_RESET_ADDR 0x00008000


/*
 * Define for each module class mastered by the CPU
 *
 */

#define __ALTERA_AVALON_JTAG_UART
#define __ALTERA_AVALON_ONCHIP_MEMORY2
#define __ALTERA_AVALON_PIO
#define __ALTERA_NIOS2_GEN2
#define __ALTERA_UP_AVALON_AUDIO
#define __ALTERA_UP_AVALON_AUDIO_AND_VIDEO_CONFIG
#define __ALTERA_UP_AVALON_VIDEO_CHARACTER_BUFFER_WITH_DMA


/*
 * RAM_NIOS_II configuration
 *
 */

#define ALT_MODULE_CLASS_RAM_NIOS_II altera_avalon_onchip_memory2
#define RAM_NIOS_II_ALLOW_IN_SYSTEM_MEMORY_CONTENT_EDITOR 0
#define RAM_NIOS_II_ALLOW_MRAM_SIM_CONTENTS_ONLY_FILE 0
#define RAM_NIOS_II_BASE 0x8000
#define RAM_NIOS_II_CONTENTS_INFO ""
#define RAM_NIOS_II_DUAL_PORT 0
#define RAM_NIOS_II_GUI_RAM_BLOCK_TYPE "AUTO"
#define RAM_NIOS_II_INIT_CONTENTS_FILE "MusicPlayerPlatformDesign_RAM_NIOS_II"
#define RAM_NIOS_II_INIT_MEM_CONTENT 1
#define RAM_NIOS_II_INSTANCE_ID "NONE"
#define RAM_NIOS_II_IRQ -1
#define RAM_NIOS_II_IRQ_INTERRUPT_CONTROLLER_ID -1
#define RAM_NIOS_II_NAME "/dev/RAM_NIOS_II"
#define RAM_NIOS_II_NON_DEFAULT_INIT_FILE_ENABLED 0
#define RAM_NIOS_II_RAM_BLOCK_TYPE "AUTO"
#define RAM_NIOS_II_READ_DURING_WRITE_MODE "DONT_CARE"
#define RAM_NIOS_II_SINGLE_CLOCK_OP 0
#define RAM_NIOS_II_SIZE_MULTIPLE 1
#define RAM_NIOS_II_SIZE_VALUE 32768
#define RAM_NIOS_II_SPAN 32768
#define RAM_NIOS_II_TYPE "altera_avalon_onchip_memory2"
#define RAM_NIOS_II_WRITABLE 1


/*
 * REG_BTN_INPUT configuration
 *
 */

#define ALT_MODULE_CLASS_REG_BTN_INPUT altera_avalon_pio
#define REG_BTN_INPUT_BASE 0x13030
#define REG_BTN_INPUT_BIT_CLEARING_EDGE_REGISTER 1
#define REG_BTN_INPUT_BIT_MODIFYING_OUTPUT_REGISTER 0
#define REG_BTN_INPUT_CAPTURE 1
#define REG_BTN_INPUT_DATA_WIDTH 4
#define REG_BTN_INPUT_DO_TEST_BENCH_WIRING 0
#define REG_BTN_INPUT_DRIVEN_SIM_VALUE 0
#define REG_BTN_INPUT_EDGE_TYPE "FALLING"
#define REG_BTN_INPUT_FREQ 50000000
#define REG_BTN_INPUT_HAS_IN 1
#define REG_BTN_INPUT_HAS_OUT 0
#define REG_BTN_INPUT_HAS_TRI 0
#define REG_BTN_INPUT_IRQ 1
#define REG_BTN_INPUT_IRQ_INTERRUPT_CONTROLLER_ID 0
#define REG_BTN_INPUT_IRQ_TYPE "EDGE"
#define REG_BTN_INPUT_NAME "/dev/REG_BTN_INPUT"
#define REG_BTN_INPUT_RESET_VALUE 0
#define REG_BTN_INPUT_SPAN 16
#define REG_BTN_INPUT_TYPE "altera_avalon_pio"


/*
 * REG_SW_INPUT configuration
 *
 */

#define ALT_MODULE_CLASS_REG_SW_INPUT altera_avalon_pio
#define REG_SW_INPUT_BASE 0x13020
#define REG_SW_INPUT_BIT_CLEARING_EDGE_REGISTER 1
#define REG_SW_INPUT_BIT_MODIFYING_OUTPUT_REGISTER 0
#define REG_SW_INPUT_CAPTURE 1
#define REG_SW_INPUT_DATA_WIDTH 1
#define REG_SW_INPUT_DO_TEST_BENCH_WIRING 0
#define REG_SW_INPUT_DRIVEN_SIM_VALUE 0
#define REG_SW_INPUT_EDGE_TYPE "FALLING"
#define REG_SW_INPUT_FREQ 50000000
#define REG_SW_INPUT_HAS_IN 1
#define REG_SW_INPUT_HAS_OUT 0
#define REG_SW_INPUT_HAS_TRI 0
#define REG_SW_INPUT_IRQ 2
#define REG_SW_INPUT_IRQ_INTERRUPT_CONTROLLER_ID 0
#define REG_SW_INPUT_IRQ_TYPE "EDGE"
#define REG_SW_INPUT_NAME "/dev/REG_SW_INPUT"
#define REG_SW_INPUT_RESET_VALUE 0
#define REG_SW_INPUT_SPAN 16
#define REG_SW_INPUT_TYPE "altera_avalon_pio"


/*
 * System configuration
 *
 */

#define ALT_DEVICE_FAMILY "Cyclone V"
#define ALT_IRQ_BASE NULL
#define ALT_LEGACY_INTERRUPT_API_PRESENT
#define ALT_LOG_PORT "/dev/null"
#define ALT_LOG_PORT_BASE 0x0
#define ALT_LOG_PORT_DEV null
#define ALT_LOG_PORT_TYPE ""
#define ALT_NUM_EXTERNAL_INTERRUPT_CONTROLLERS 0
#define ALT_NUM_INTERNAL_INTERRUPT_CONTROLLERS 1
#define ALT_NUM_INTERRUPT_CONTROLLERS 1
#define ALT_STDERR "/dev/UART_NIOS_II"
#define ALT_STDERR_BASE 0x13060
#define ALT_STDERR_DEV UART_NIOS_II
#define ALT_STDERR_IS_JTAG_UART
#define ALT_STDERR_PRESENT
#define ALT_STDERR_TYPE "altera_avalon_jtag_uart"
#define ALT_STDIN "/dev/UART_NIOS_II"
#define ALT_STDIN_BASE 0x13060
#define ALT_STDIN_DEV UART_NIOS_II
#define ALT_STDIN_IS_JTAG_UART
#define ALT_STDIN_PRESENT
#define ALT_STDIN_TYPE "altera_avalon_jtag_uart"
#define ALT_STDOUT "/dev/UART_NIOS_II"
#define ALT_STDOUT_BASE 0x13060
#define ALT_STDOUT_DEV UART_NIOS_II
#define ALT_STDOUT_IS_JTAG_UART
#define ALT_STDOUT_PRESENT
#define ALT_STDOUT_TYPE "altera_avalon_jtag_uart"
#define ALT_SYSTEM_NAME "MusicPlayerPlatformDesign"
#define ALT_SYS_CLK_TICKS_PER_SEC NONE_TICKS_PER_SEC
#define ALT_TIMESTAMP_CLK_TIMER_DEVICE_TYPE NONE_TIMER_DEVICE_TYPE


/*
 * TIMER_CTRL_OUTPUT configuration
 *
 */

#define ALT_MODULE_CLASS_TIMER_CTRL_OUTPUT altera_avalon_pio
#define TIMER_CTRL_OUTPUT_BASE 0x13000
#define TIMER_CTRL_OUTPUT_BIT_CLEARING_EDGE_REGISTER 0
#define TIMER_CTRL_OUTPUT_BIT_MODIFYING_OUTPUT_REGISTER 0
#define TIMER_CTRL_OUTPUT_CAPTURE 0
#define TIMER_CTRL_OUTPUT_DATA_WIDTH 2
#define TIMER_CTRL_OUTPUT_DO_TEST_BENCH_WIRING 0
#define TIMER_CTRL_OUTPUT_DRIVEN_SIM_VALUE 0
#define TIMER_CTRL_OUTPUT_EDGE_TYPE "NONE"
#define TIMER_CTRL_OUTPUT_FREQ 50000000
#define TIMER_CTRL_OUTPUT_HAS_IN 0
#define TIMER_CTRL_OUTPUT_HAS_OUT 1
#define TIMER_CTRL_OUTPUT_HAS_TRI 0
#define TIMER_CTRL_OUTPUT_IRQ -1
#define TIMER_CTRL_OUTPUT_IRQ_INTERRUPT_CONTROLLER_ID -1
#define TIMER_CTRL_OUTPUT_IRQ_TYPE "NONE"
#define TIMER_CTRL_OUTPUT_NAME "/dev/TIMER_CTRL_OUTPUT"
#define TIMER_CTRL_OUTPUT_RESET_VALUE 0
#define TIMER_CTRL_OUTPUT_SPAN 16
#define TIMER_CTRL_OUTPUT_TYPE "altera_avalon_pio"


/*
 * TIMER_STATUS_INPUT configuration
 *
 */

#define ALT_MODULE_CLASS_TIMER_STATUS_INPUT altera_avalon_pio
#define TIMER_STATUS_INPUT_BASE 0x13010
#define TIMER_STATUS_INPUT_BIT_CLEARING_EDGE_REGISTER 1
#define TIMER_STATUS_INPUT_BIT_MODIFYING_OUTPUT_REGISTER 0
#define TIMER_STATUS_INPUT_CAPTURE 1
#define TIMER_STATUS_INPUT_DATA_WIDTH 2
#define TIMER_STATUS_INPUT_DO_TEST_BENCH_WIRING 0
#define TIMER_STATUS_INPUT_DRIVEN_SIM_VALUE 0
#define TIMER_STATUS_INPUT_EDGE_TYPE "RISING"
#define TIMER_STATUS_INPUT_FREQ 50000000
#define TIMER_STATUS_INPUT_HAS_IN 1
#define TIMER_STATUS_INPUT_HAS_OUT 0
#define TIMER_STATUS_INPUT_HAS_TRI 0
#define TIMER_STATUS_INPUT_IRQ -1
#define TIMER_STATUS_INPUT_IRQ_INTERRUPT_CONTROLLER_ID -1
#define TIMER_STATUS_INPUT_IRQ_TYPE "NONE"
#define TIMER_STATUS_INPUT_NAME "/dev/TIMER_STATUS_INPUT"
#define TIMER_STATUS_INPUT_RESET_VALUE 0
#define TIMER_STATUS_INPUT_SPAN 16
#define TIMER_STATUS_INPUT_TYPE "altera_avalon_pio"


/*
 * UART_NIOS_II configuration
 *
 */

#define ALT_MODULE_CLASS_UART_NIOS_II altera_avalon_jtag_uart
#define UART_NIOS_II_BASE 0x13060
#define UART_NIOS_II_IRQ 0
#define UART_NIOS_II_IRQ_INTERRUPT_CONTROLLER_ID 0
#define UART_NIOS_II_NAME "/dev/UART_NIOS_II"
#define UART_NIOS_II_READ_DEPTH 64
#define UART_NIOS_II_READ_THRESHOLD 8
#define UART_NIOS_II_SPAN 8
#define UART_NIOS_II_TYPE "altera_avalon_jtag_uart"
#define UART_NIOS_II_WRITE_DEPTH 64
#define UART_NIOS_II_WRITE_THRESHOLD 8


/*
 * VGA_CHAR_BUFFER_avalon_char_buffer_slave configuration
 *
 */

#define ALT_MODULE_CLASS_VGA_CHAR_BUFFER_avalon_char_buffer_slave altera_up_avalon_video_character_buffer_with_dma
#define VGA_CHAR_BUFFER_AVALON_CHAR_BUFFER_SLAVE_BASE 0x10000
#define VGA_CHAR_BUFFER_AVALON_CHAR_BUFFER_SLAVE_IRQ -1
#define VGA_CHAR_BUFFER_AVALON_CHAR_BUFFER_SLAVE_IRQ_INTERRUPT_CONTROLLER_ID -1
#define VGA_CHAR_BUFFER_AVALON_CHAR_BUFFER_SLAVE_NAME "/dev/VGA_CHAR_BUFFER_avalon_char_buffer_slave"
#define VGA_CHAR_BUFFER_AVALON_CHAR_BUFFER_SLAVE_SPAN 8192
#define VGA_CHAR_BUFFER_AVALON_CHAR_BUFFER_SLAVE_TYPE "altera_up_avalon_video_character_buffer_with_dma"


/*
 * VGA_CHAR_BUFFER_avalon_char_control_slave configuration
 *
 */

#define ALT_MODULE_CLASS_VGA_CHAR_BUFFER_avalon_char_control_slave altera_up_avalon_video_character_buffer_with_dma
#define VGA_CHAR_BUFFER_AVALON_CHAR_CONTROL_SLAVE_BASE 0x13068
#define VGA_CHAR_BUFFER_AVALON_CHAR_CONTROL_SLAVE_IRQ -1
#define VGA_CHAR_BUFFER_AVALON_CHAR_CONTROL_SLAVE_IRQ_INTERRUPT_CONTROLLER_ID -1
#define VGA_CHAR_BUFFER_AVALON_CHAR_CONTROL_SLAVE_NAME "/dev/VGA_CHAR_BUFFER_avalon_char_control_slave"
#define VGA_CHAR_BUFFER_AVALON_CHAR_CONTROL_SLAVE_SPAN 8
#define VGA_CHAR_BUFFER_AVALON_CHAR_CONTROL_SLAVE_TYPE "altera_up_avalon_video_character_buffer_with_dma"


/*
 * hal configuration
 *
 */

#define ALT_INCLUDE_INSTRUCTION_RELATED_EXCEPTION_API
#define ALT_MAX_FD 4
#define ALT_SYS_CLK none
#define ALT_TIMESTAMP_CLK none

#endif /* __SYSTEM_H_ */
