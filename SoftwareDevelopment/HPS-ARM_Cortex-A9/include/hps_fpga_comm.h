#ifndef HPS_FPGA_COMM_H
#define HPS_FPGA_COMM_H

#include <stdint.h>
#include <stddef.h>
#include "shared_protocol.h"

int hps_fpga_init(uintptr_t phys_base, size_t map_size);
void hps_fpga_close(void);

volatile shared_audio_mem_t *hps_fpga_get_shared(void);

#endif /* HPS_FPGA_COMM_H */